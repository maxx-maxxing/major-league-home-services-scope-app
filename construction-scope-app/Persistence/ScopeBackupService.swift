import Foundation
import SwiftData

enum ScopeBackupConflictPolicy: Hashable { case skipExisting, keepBoth }

struct ScopeBackupRestoreResult {
    let restoredCount: Int
    let skippedCount: Int
}

struct StagedScopeBackup {
    let records: [ScopeBackupRecord]
    let assetCount: Int
    let totalAssetBytes: Int
    fileprivate let directoryURL: URL
    fileprivate let manifestSHA256: String
}

private struct ScopeBackupRestoreJournal: Codable {
    static let maximumBytes = 64 * 1_024
    // Version 1 duplicated review payloads that could exceed its 8 MiB reader.
    // Its original archive limit plus ID overhead bounds migration recovery.
    static let maximumLegacyBytes = ScopeBackupArchive.maximumArchiveBytes + maximumBytes
    let formatVersion: Int
    let transactionID: UUID
    let scopeIDs: [UUID]

    private enum CodingKeys: String, CodingKey { case formatVersion, transactionID, scopeIDs, reviewStates }
    private struct ReviewKey: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }

    init(transactionID: UUID, scopeIDs: [UUID]) {
        formatVersion = 2
        self.transactionID = transactionID
        self.scopeIDs = scopeIDs
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        formatVersion = try values.decodeIfPresent(Int.self, forKey: .formatVersion) ?? 1
        guard formatVersion == 1 || formatVersion == 2 else { throw ScopeBackupError.recoveryRequired }
        transactionID = try values.decode(UUID.self, forKey: .transactionID)
        scopeIDs = try values.decode([UUID].self, forKey: .scopeIDs)
        if formatVersion == 1 {
            // Old marks are never replayed. Inspect only owning IDs, avoiding a
            // second allocation of potentially very large, unused review keys.
            let legacy = try values.nestedContainer(keyedBy: ReviewKey.self, forKey: .reviewStates)
            guard Set(legacy.allKeys.map(\.stringValue)) == Set(scopeIDs.map(\.uuidString)) else { throw ScopeBackupError.recoveryRequired }
            for key in legacy.allKeys { _ = try legacy.nestedContainer(keyedBy: ReviewKey.self, forKey: key) }
        } else if values.contains(.reviewStates) {
            throw ScopeBackupError.recoveryRequired
        }
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(formatVersion, forKey: .formatVersion)
        try values.encode(transactionID, forKey: .transactionID)
        try values.encode(scopeIDs, forKey: .scopeIDs)
    }
}

private struct ScopeBackupFileSnapshot: @unchecked Sendable {
    let records: [ScopeBackupRecord]
}

/// Never opens an arbitrary store, overwrites a row, or performs a network operation.
/// Metadata uses a separate context so a restore failure cannot roll back the editor's work.
@MainActor
final class ScopeBackupService {
    private let container: ModelContainer
    private let reviewStore: SectionReviewStore
    private let supportDirectory: URL
    private var assetsRoot: URL { supportDirectory.appendingPathComponent("ScopeAssets", isDirectory: true) }
    private var stagingRoot: URL { supportDirectory.appendingPathComponent("ScopeBackupStaging", isDirectory: true) }
    private var journalURL: URL { supportDirectory.appendingPathComponent("ScopeBackupRestoreJournal.json") }
    private static var activeRoots: Set<String> = []
    private static var liveStagePaths: Set<String> = []

    init(container: ModelContainer, reviewStore: SectionReviewStore, supportDirectory: URL? = nil) {
        self.container = container
        self.reviewStore = reviewStore
        self.supportDirectory = supportDirectory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    func export(scopes: [JobScope]) async throws -> URL {
        try beginOperation()
        defer { endOperation() }
        do {
            try reconcileJournal()
            let records = try snapshot(scopes)
            for record in records { try record.validateModelEncodingFidelity() }
            let snapshot = ScopeBackupFileSnapshot(records: records)
            let root = assetsRoot
            let data = try await Task.detached(priority: .userInitiated) {
                try ScopeBackupArchive.encode(records: snapshot.records, assetsRoot: root)
            }.value
            try Task.checkCancellation()
            guard try records == self.snapshot(scopes) else { throw ScopeBackupError.changedDuringExport }
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ScopesBackupExports", isDirectory: true).appendingPathComponent(UUID().uuidString, isDirectory: true)
            try ScopeBackupFiles.makeDirectory(folder)
            let url = folder.appendingPathComponent("Scopes-\(Self.filenameDate()).scopebackup")
            try data.write(to: url, options: .atomic)
            return url
        } catch { throw safeError(error) }
    }

    func stage(fileURL: URL) async throws -> StagedScopeBackup {
        try beginOperation()
        defer { endOperation() }
        var preparedDirectory: URL?
        do {
            try reconcileJournal()
            let root = stagingRoot
            let directory = root.appendingPathComponent(UUID().uuidString, isDirectory: true)
            preparedDirectory = directory
            let contents = try await Task.detached(priority: .userInitiated) {
                let didAccess = fileURL.startAccessingSecurityScopedResource()
                defer { if didAccess { fileURL.stopAccessingSecurityScopedResource() } }
                var readError: Error?
                var coordinationError: NSError?
                var value: ScopeBackupContents?
                NSFileCoordinator().coordinate(readingItemAt: fileURL, options: .withoutChanges, error: &coordinationError) { url in
                    do {
                        try ScopeBackupFiles.rejectLinks(at: url)
                        let info = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                        guard info.isRegularFile == true else { throw ScopeBackupError.unsafeFile }
                        guard let size = info.fileSize, size <= ScopeBackupArchive.maximumArchiveBytes else { throw ScopeBackupError.sizeLimit }
                        let data = try ScopeBackupFiles.read(url, limit: ScopeBackupArchive.maximumArchiveBytes)
                        let contents = try ScopeBackupArchive.validate(data: data)
                        for record in contents.records { try record.validateModelEncodingFidelity() }
                        try ScopeBackupFiles.makeDirectory(directory)
                        try Data("Scopes backup workspace v1".utf8).write(to: directory.appendingPathComponent("workspace.marker"), options: .atomic)
                        try data.write(to: directory.appendingPathComponent("archive.scopebackup"), options: .atomic)
                        value = contents
                    } catch { readError = error }
                }
                if let readError { throw readError }
                if let coordinationError { throw coordinationError }
                guard let value else { throw ScopeBackupError.invalidArchive }
                return value
            }.value
            try Task.checkCancellation()
            Self.liveStagePaths.insert(directory.standardizedFileURL.path)
            return StagedScopeBackup(records: contents.records, assetCount: contents.assetCount, totalAssetBytes: contents.totalAssetBytes, directoryURL: directory, manifestSHA256: contents.manifestSHA256)
        } catch {
            if let preparedDirectory { removeStagingDirectory(preparedDirectory) }
            throw safeError(error)
        }
    }

    func conflicts(in staged: StagedScopeBackup) throws -> Set<UUID> {
        do {
            try validateStageLocation(staged.directoryURL)
            let existing = Set(try ModelContext(container).fetch(FetchDescriptor<JobScope>()).map(\.id))
            return Set(staged.records.compactMap { record in
                existing.contains(record.id) || FileManager.default.fileExists(atPath: assetsRoot.appendingPathComponent(record.id.uuidString).path) ? record.id : nil
            })
        } catch { throw safeError(error) }
    }

    func restore(_ staged: StagedScopeBackup, policy: ScopeBackupConflictPolicy) async throws -> ScopeBackupRestoreResult {
        try beginOperation()
        defer { endOperation() }
        let transactionContext = ModelContext(container)
        transactionContext.autosaveEnabled = false
        var journalWasWritten = false
        do {
            try reconcileJournal()
            try validateStageLocation(staged.directoryURL)
            let archiveURL = staged.directoryURL.appendingPathComponent("archive.scopebackup")
            let contents = try await Task.detached(priority: .userInitiated) {
                try ScopeBackupFiles.rejectLinks(at: archiveURL)
                let size = try archiveURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? Int.max
                guard size <= ScopeBackupArchive.maximumArchiveBytes else { throw ScopeBackupError.sizeLimit }
                return try ScopeBackupArchive.validate(data: ScopeBackupFiles.read(archiveURL, limit: ScopeBackupArchive.maximumArchiveBytes))
            }.value
            // The exact reviewed snapshot must still be present; do not silently swap an import.
            guard contents.records == staged.records, contents.manifestSHA256 == staged.manifestSHA256 else { throw ScopeBackupError.invalidArchive }
            let existing = Set(try transactionContext.fetch(FetchDescriptor<JobScope>()).map(\.id))
            var selected: [ScopeBackupRecord] = []
            var sourceIDs: [UUID: UUID] = [:] // target -> archived scope
            var skipped = 0
            var reserved = existing
            for var record in contents.records {
                let original = record.id
                let collision = reserved.contains(original) || FileManager.default.fileExists(atPath: assetsRoot.appendingPathComponent(original.uuidString).path)
                if collision && policy == .skipExisting { skipped += 1; continue }
                if collision {
                    repeat { record.id = UUID() }
                    while reserved.contains(record.id) || FileManager.default.fileExists(atPath: assetsRoot.appendingPathComponent(record.id.uuidString).path)
                }
                reserved.insert(record.id)
                sourceIDs[record.id] = original
                var mapping: [String: String] = [:]
                for asset in contents.assets where asset.path.hasPrefix("assets/\(original.uuidString)/") {
                    let relative = String(asset.path.dropFirst("assets/\(original.uuidString)/".count))
                    mapping[asset.path] = assetsRoot.appendingPathComponent(record.id.uuidString, isDirectory: true).appendingPathComponent(relative).path
                }
                try record.remapAssetPaths(mapping)
                try record.validateModelEncodingFidelity()
                selected.append(record)
            }
            guard !selected.isEmpty else { return ScopeBackupRestoreResult(restoredCount: 0, skippedCount: skipped) }
            try Task.checkCancellation()
            // Save and reopen a throwaway on-disk store before adopting any live files or rows.
            try preflightPersistence(selected, directory: staged.directoryURL.appendingPathComponent("Validation-\(UUID().uuidString)", isDirectory: true))
            let selectedSnapshot = ScopeBackupFileSnapshot(records: selected)
            let sourceMapping = sourceIDs
            let ready = staged.directoryURL.appendingPathComponent("Ready-\(UUID().uuidString)", isDirectory: true)
            try await Task.detached(priority: .userInitiated) {
                try ScopeBackupFiles.makeDirectory(ready)
                for record in selectedSnapshot.records {
                    guard let sourceID = sourceMapping[record.id] else { throw ScopeBackupError.invalidArchive }
                    let directory = ready.appendingPathComponent(record.id.uuidString, isDirectory: true)
                    try ScopeBackupFiles.makeDirectory(directory)
                    for asset in contents.assets where asset.path.hasPrefix("assets/\(sourceID.uuidString)/") {
                        let relative = String(asset.path.dropFirst("assets/\(sourceID.uuidString)/".count))
                        let destination = directory.appendingPathComponent(relative)
                        try ScopeBackupFiles.makeDirectory(destination.deletingLastPathComponent())
                        try ScopeBackupFiles.writeNew(asset.data, to: destination)
                        // Checklist ordering/createdAt are reconstructed from file attributes.
                        var attributes: [FileAttributeKey: Any] = [:]
                        if let createdAt = asset.createdAt { attributes[.creationDate] = createdAt }
                        if let modifiedAt = asset.modifiedAt { attributes[.modificationDate] = modifiedAt }
                        if !attributes.isEmpty { try FileManager.default.setAttributes(attributes, ofItemAtPath: destination.path) }
                    }
                    // Re-read the complete prepared set before adoption. No live
                    // rows or files are touched if destination semantics differ.
                    for asset in contents.assets where asset.path.hasPrefix("assets/\(sourceID.uuidString)/") {
                        let relative = String(asset.path.dropFirst("assets/\(sourceID.uuidString)/".count))
                        let prepared = try ScopeBackupFiles.read(directory.appendingPathComponent(relative), limit: ScopeBackupArchive.maximumAssetBytes)
                        guard ScopeBackupArchive.digest(prepared) == asset.sha256 else { throw ScopeBackupError.invalidArchive }
                    }
                }
            }.value
            try Task.checkCancellation()
            // Recheck immediately before adoption; another app window may have saved during file work.
            let nowExisting = Set(try ModelContext(container).fetch(FetchDescriptor<JobScope>()).map(\.id))
            guard selected.allSatisfy({ !nowExisting.contains($0.id) && !FileManager.default.fileExists(atPath: assetsRoot.appendingPathComponent($0.id.uuidString).path) }) else { throw ScopeBackupError.changedDuringExport }
            let states = Dictionary(uniqueKeysWithValues: selected.map { ($0.id, $0.reviewState) })
            let journal = ScopeBackupRestoreJournal(transactionID: UUID(), scopeIDs: selected.map(\.id))
            let journalData = try JSONEncoder().encode(journal)
            guard journalData.count <= ScopeBackupRestoreJournal.maximumBytes else { throw ScopeBackupError.sizeLimit }
            try ScopeBackupFiles.makeDirectory(supportDirectory)
            try ScopeBackupFiles.rejectLinks(at: journalURL, allowMissing: true)
            try journalData.write(to: journalURL, options: .atomic)
            journalWasWritten = true
            try ScopeBackupFiles.makeDirectory(assetsRoot)
            for record in selected {
                let destination = assetsRoot.appendingPathComponent(record.id.uuidString, isDirectory: true)
                try ScopeBackupFiles.rejectLinks(at: destination, allowMissing: true)
                try FileManager.default.moveItem(at: ready.appendingPathComponent(record.id.uuidString), to: destination)
            }
            try validateReviewLocation()
            try reviewStore.restoreReviewStates(states)
            for record in selected { transactionContext.insert(try record.makeScope()) }
            try transactionContext.save()
            // Once metadata is committed, journal recovery will retain adopted files and marks.
            try reconcileJournal()
            return ScopeBackupRestoreResult(restoredCount: selected.count, skippedCount: skipped)
        } catch {
            transactionContext.rollback()
            if journalWasWritten {
                do { try reconcileJournal() }
                catch { throw ScopeBackupError.recoveryRequired }
            }
            throw safeError(error)
        }
    }

    func recoverInterruptedRestores() throws {
        try beginOperation()
        defer { endOperation() }
        do {
            try reconcileJournal()
            try removeAbandonedStaging()
        }
        catch { throw ScopeBackupError.recoveryRequired }
    }

    func discard(_ staged: StagedScopeBackup) { removeStagingDirectory(staged.directoryURL) }

    func discardExport(fileURL: URL) {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("ScopesBackupExports", isDirectory: true)
        let folder = fileURL.deletingLastPathComponent()
        guard folder.deletingLastPathComponent().standardizedFileURL == root.standardizedFileURL,
              UUID(uuidString: folder.lastPathComponent) != nil,
              (try? ScopeBackupFiles.rejectLinks(at: folder)) != nil else { return }
        try? FileManager.default.removeItem(at: folder)
    }

    private func snapshot(_ scopes: [JobScope]) throws -> [ScopeBackupRecord] {
        try validateReviewLocation()
        return try scopes.map { try ScopeBackupRecord(scope: $0, reviewState: reviewStore.backupReviewState(for: $0.id)) }
    }

    private func preflightPersistence(_ records: [ScopeBackupRecord], directory: URL) throws {
        try ScopeBackupFiles.makeDirectory(directory)
        let schema = Schema([JobScope.self])
        let configuration = ModelConfiguration("BackupValidation", schema: schema, url: directory.appendingPathComponent("Validation.store"), allowsSave: true, cloudKitDatabase: .none)
        let scratch = try ModelContainer(for: schema, configurations: [configuration])
        let writer = ModelContext(scratch)
        writer.autosaveEnabled = false
        for record in records { writer.insert(try record.makeScope()) }
        try writer.save()
        let reader = ModelContext(scratch)
        let reopened = try reader.fetch(FetchDescriptor<JobScope>())
        guard reopened.count == records.count else { throw ScopeBackupError.invalidArchive }
        for record in records {
            guard let scope = reopened.first(where: { $0.id == record.id }), ScopeBackupRecord(scope: scope, reviewState: record.reviewState) == record else { throw ScopeBackupError.invalidArchive }
        }
    }

    private func reconcileJournal() throws {
        try ScopeBackupFiles.rejectLinks(at: supportDirectory, allowMissing: true)
        guard FileManager.default.fileExists(atPath: journalURL.path) else { return }
        try ScopeBackupFiles.rejectLinks(at: journalURL)
        let journalData = try ScopeBackupFiles.read(journalURL, limit: ScopeBackupRestoreJournal.maximumLegacyBytes)
        let journal = try JSONDecoder().decode(ScopeBackupRestoreJournal.self, from: journalData)
        guard journal.formatVersion == 1 || journalData.count <= ScopeBackupRestoreJournal.maximumBytes else { throw ScopeBackupError.recoveryRequired }
        guard !journal.scopeIDs.isEmpty, journal.scopeIDs.count <= ScopeBackupArchive.maximumScopeCount,
              Set(journal.scopeIDs).count == journal.scopeIDs.count else { throw ScopeBackupError.recoveryRequired }
        let saved = Set(try ModelContext(container).fetch(FetchDescriptor<JobScope>()).map(\.id))
        var states: [UUID: [String: Date]] = [:]
        for id in journal.scopeIDs {
            let directory = assetsRoot.appendingPathComponent(id.uuidString, isDirectory: true)
            try ScopeBackupFiles.rejectLinks(at: directory, allowMissing: true)
            if saved.contains(id) {
                guard FileManager.default.fileExists(atPath: directory.path) else { throw ScopeBackupError.recoveryRequired }
                // Review state was persisted before the model commit. Do not replay
                // old marks over edits the user may have made after a cleanup error.
                _ = try reviewStore.backupReviewState(for: id)
            } else {
                // Only IDs registered before adoption and still absent from the store may be rolled back.
                if FileManager.default.fileExists(atPath: directory.path) { try FileManager.default.removeItem(at: directory) }
                states[id] = [:]
            }
        }
        try validateReviewLocation()
        try reviewStore.restoreReviewStates(states)
        try FileManager.default.removeItem(at: journalURL)
    }

    private func validateReviewLocation() throws {
        try ScopeBackupFiles.rejectLinks(at: supportDirectory.appendingPathComponent("WorkflowState", isDirectory: true).appendingPathComponent("SectionReviewState.json"), allowMissing: true)
    }

    private func beginOperation() throws {
        guard Self.activeRoots.insert(supportDirectory.resolvingSymlinksInPath().path).inserted else { throw ScopeBackupError.saveRequired }
    }
    private func endOperation() { Self.activeRoots.remove(supportDirectory.resolvingSymlinksInPath().path) }

    private func validateStageLocation(_ directory: URL) throws {
        guard directory.deletingLastPathComponent().standardizedFileURL == stagingRoot.standardizedFileURL,
              UUID(uuidString: directory.lastPathComponent) != nil else { throw ScopeBackupError.unsafeFile }
        try ScopeBackupFiles.rejectLinks(at: directory)
    }

    private func removeStagingDirectory(_ directory: URL) {
        Self.liveStagePaths.remove(directory.standardizedFileURL.path)
        guard (try? validateStageLocation(directory)) != nil else { return }
        try? FileManager.default.removeItem(at: directory)
    }

    private func removeAbandonedStaging() throws {
        guard FileManager.default.fileExists(atPath: stagingRoot.path) else { return }
        try ScopeBackupFiles.rejectLinks(at: stagingRoot)
        for directory in try FileManager.default.contentsOfDirectory(at: stagingRoot, includingPropertiesForKeys: [.isDirectoryKey]) {
            guard UUID(uuidString: directory.lastPathComponent) != nil,
                  !Self.liveStagePaths.contains(directory.standardizedFileURL.path) else { continue }
            try validateStageLocation(directory)
            let marker = directory.appendingPathComponent("workspace.marker")
            guard FileManager.default.fileExists(atPath: marker.path),
                  try ScopeBackupFiles.read(marker, limit: 100) == Data("Scopes backup workspace v1".utf8) else { continue }
            try FileManager.default.removeItem(at: directory)
        }
    }

    private func safeError(_ error: Error) -> Error {
        if error is ScopeBackupError || error is ScopeBackupRecordError { return error }
        return ScopeBackupError.fileOperation
    }

    private static func filenameDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: .now)
    }
}
