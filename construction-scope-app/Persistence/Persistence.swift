import Foundation
import SwiftUI
import SwiftData

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer
    let startupIssue: PersistenceStartupIssue?

    private init(inMemory: Bool = false) {
        let schema = Schema([JobScope.self])
        let persistedConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )

        do {
            container = try ModelContainer(for: schema, configurations: [persistedConfiguration])
            startupIssue = nil
        } catch {
            startupIssue = PersistenceStartupIssue(underlyingError: error)
            do {
                let fallbackConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                container = try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                preconditionFailure("Failed to create fallback in-memory ModelContainer: \(error)")
            }
        }
    }
}

struct PersistenceStartupIssue: LocalizedError {
    let underlyingError: Error

    var errorDescription: String? {
        "The local scope store could not be opened."
    }

    var recoverySuggestion: String? {
        "Do not continue editing on this build. Preserve the installed app state and investigate store compatibility before shipping the next beta update."
    }

    var detailedDescription: String {
        [
            errorDescription,
            recoverySuggestion,
            "Underlying error: \(underlyingError.localizedDescription)"
        ]
        .compactMap { $0 }
        .joined(separator: "\n")
    }
}

@MainActor
final class DebouncedAutosave: ObservableObject {
    let persistenceHealth: PersistenceSaveHealth

    private var pendingSaveTask: Task<Void, Never>?
    private var pendingScope: JobScope?
    private let delay: TimeInterval

    init(
        delay: TimeInterval = 0.8,
        persistenceHealth: PersistenceSaveHealth? = nil
    ) {
        self.delay = delay
        self.persistenceHealth = persistenceHealth ?? PersistenceSaveHealth()
    }

    func configure(with modelContext: ModelContext) {
        persistenceHealth.configure {
            try modelContext.save()
        }
    }

    func scheduleSave(for scope: JobScope) {
        pendingSaveTask?.cancel()
        pendingScope = scope

        pendingSaveTask = Task { [weak self] in
            guard let self else { return }

            let delayNanos = UInt64(self.delay * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delayNanos)

            guard !Task.isCancelled else { return }

            scope.updatedAt = .now
            self.pendingScope = nil
            self.pendingSaveTask = nil
            self.saveNow(.autosave)
        }
    }

    @discardableResult
    func flush(
        scope: JobScope,
        afterConfirmedSave action: PersistenceSaveHealth.ConfirmedSaveAction? = nil
    ) -> Bool {
        pendingSaveTask?.cancel()
        pendingScope = nil
        scope.updatedAt = .now
        return saveNow(.manualFlush, afterConfirmedSave: action)
    }

    /// Freeze the pending edit timestamp before the backup sheet takes its snapshot.
    /// This saves the existing context; it never rolls back unrelated edits.
    @discardableResult
    func prepareForBackup() -> Bool {
        pendingSaveTask?.cancel()
        pendingSaveTask = nil
        pendingScope?.updatedAt = .now
        pendingScope = nil
        return saveNow(.manualFlush)
    }

    @discardableResult
    func saveNow(
        _ operation: PersistenceSaveOperation,
        afterConfirmedSave action: PersistenceSaveHealth.ConfirmedSaveAction? = nil
    ) -> Bool {
        persistenceHealth.attempt(operation, afterConfirmedSave: action)
    }
}

@MainActor
final class SectionReviewStore: ObservableObject {
    @Published private var completedSectionsByScope: [UUID: [ScopeSection: Date]] = [:]
    private var dirtyReviewKeys: [UUID: Set<String>] = [:]

    private let fileManager: FileManager
    private let fileURL: URL

    init(fileManager: FileManager = .default, supportDirectory: URL? = nil) {
        self.fileManager = fileManager
        self.fileURL = supportDirectory.map {
            $0.appendingPathComponent("WorkflowState", isDirectory: true).appendingPathComponent("SectionReviewState.json")
        } ?? Self.defaultFileURL(fileManager: fileManager)
        load()
    }

    /// Include future/unrecognized review keys from disk as well as current in-memory marks.
    /// Corrupt sidecars fail export rather than silently producing an incomplete backup.
    func backupReviewState(for scopeID: UUID) throws -> [String: Date] {
        let payload = try backupPayload()
        return Dictionary(uniqueKeysWithValues: (payload.scopes.first { $0.scopeID == scopeID }?.completedSections ?? []).map { ($0.sectionKey, $0.completedAt) })
    }

    /// Restore only the explicitly supplied scope IDs. Empty state removes those IDs' marks.
    /// The restore service only supplies newly adopted IDs, never existing conflicting scopes.
    func restoreReviewStates(_ states: [UUID: [String: Date]]) throws {
        var payload = try backupPayload()
        payload.scopes.removeAll { states[$0.scopeID] != nil }
        for (id, state) in states where !state.isEmpty {
            payload.scopes.append(ScopeReviewRecord(scopeID: id, completedSections: state.map { CompletedSectionRecord(sectionKey: $0.key, completedAt: $0.value) }.sorted { $0.sectionKey < $1.sectionKey }))
        }
        payload.scopes.sort { $0.scopeID.uuidString < $1.scopeID.uuidString }
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(payload).write(to: fileURL, options: .atomic)
        completedSectionsByScope = payload.inMemoryState
        dirtyReviewKeys = [:]
    }

    private func backupPayload() throws -> SectionReviewPayload {
        var merged: [UUID: [String: Date]] = [:]
        if fileManager.fileExists(atPath: fileURL.path) {
            let disk = try JSONDecoder().decode(SectionReviewPayload.self, from: Data(contentsOf: fileURL))
            guard Set(disk.scopes.map(\.scopeID)).count == disk.scopes.count else {
                throw CocoaError(.fileReadCorruptFile)
            }
            for scope in disk.scopes {
                guard Set(scope.completedSections.map(\.sectionKey)).count == scope.completedSections.count else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                for section in scope.completedSections {
                    merged[scope.scopeID, default: [:]][section.sectionKey] = section.completedAt
                }
            }
        }
        // Only locally edited section keys overlay disk. Another window may have
        // written unrelated scope/section marks since this instance was loaded.
        for (scopeID, keys) in dirtyReviewKeys {
            for key in keys {
                guard let section = ScopeSection.section(reviewStateKey: key) else { continue }
                var state = merged[scopeID] ?? [:]
                for oldKey in Array(state.keys) where ScopeSection.section(reviewStateKey: oldKey) == section { state[oldKey] = nil }
                state[section.reviewStateKey] = completedSectionsByScope[scopeID]?[section]
                merged[scopeID] = state
            }
        }
        return SectionReviewPayload(scopes: merged.filter { !$0.value.isEmpty }.map { id, state in
            ScopeReviewRecord(scopeID: id, completedSections: state.map { CompletedSectionRecord(sectionKey: $0.key, completedAt: $0.value) })
        })
    }

    func isComplete(_ section: ScopeSection, in scope: JobScope) -> Bool {
        completedAt(for: section, in: scope) != nil
    }

    func completedAt(for section: ScopeSection, in scope: JobScope) -> Date? {
        completedSectionsByScope[scope.id]?[section]
    }

    func markComplete(_ section: ScopeSection, in scope: JobScope) {
        var scopeSections = completedSectionsByScope[scope.id] ?? [:]
        scopeSections[section] = .now
        completedSectionsByScope[scope.id] = scopeSections
        dirtyReviewKeys[scope.id, default: []].insert(section.reviewStateKey)
        persist()
    }

    func invalidate(_ section: ScopeSection, in scope: JobScope) {
        guard var scopeSections = completedSectionsByScope[scope.id],
              scopeSections[section] != nil else {
            return
        }

        scopeSections[section] = nil
        completedSectionsByScope[scope.id] = scopeSections.isEmpty ? nil : scopeSections
        dirtyReviewKeys[scope.id, default: []].insert(section.reviewStateKey)
        persist()
    }

    private func load() {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let payload = try JSONDecoder().decode(SectionReviewPayload.self, from: data)
            completedSectionsByScope = payload.inMemoryState
        } catch {
            assertionFailure("Failed to load section review state: \(error)")
            completedSectionsByScope = [:]
        }
    }

    private func persist() {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let payload = try backupPayload()
            let data = try encoder.encode(payload)
            try data.write(to: fileURL, options: .atomic)
            completedSectionsByScope = payload.inMemoryState
            dirtyReviewKeys = [:]
        } catch {
            assertionFailure("Failed to persist section review state: \(error)")
        }
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL {
        let supportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return supportDirectory
            .appendingPathComponent("WorkflowState", isDirectory: true)
            .appendingPathComponent("SectionReviewState.json", isDirectory: false)
    }
}

private struct SectionReviewPayload: Codable {
    var scopes: [ScopeReviewRecord]

    init(scopes: [ScopeReviewRecord] = []) {
        self.scopes = scopes
    }

    init(completedSectionsByScope: [UUID: [ScopeSection: Date]]) {
        scopes = completedSectionsByScope.compactMap { scopeID, completedSections in
            let sectionRecords = ScopeSection.allCases.compactMap { section -> CompletedSectionRecord? in
                guard let completedAt = completedSections[section] else { return nil }
                return CompletedSectionRecord(sectionKey: section.reviewStateKey, completedAt: completedAt)
            }

            guard !sectionRecords.isEmpty else { return nil }
            return ScopeReviewRecord(scopeID: scopeID, completedSections: sectionRecords)
        }
        .sorted { $0.scopeID.uuidString < $1.scopeID.uuidString }
    }

    var inMemoryState: [UUID: [ScopeSection: Date]] {
        var result: [UUID: [ScopeSection: Date]] = [:]

        for scope in scopes {
            var completedSections: [ScopeSection: Date] = [:]

            for record in scope.completedSections {
                guard let section = ScopeSection.section(reviewStateKey: record.sectionKey) else { continue }
                completedSections[section] = record.completedAt
            }

            if !completedSections.isEmpty {
                result[scope.scopeID] = completedSections
            }
        }

        return result
    }
}

private struct ScopeReviewRecord: Codable {
    var scopeID: UUID
    var completedSections: [CompletedSectionRecord]
}

private struct CompletedSectionRecord: Codable {
    var sectionKey: String
    var completedAt: Date
}
