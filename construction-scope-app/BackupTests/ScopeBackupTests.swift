import Foundation
import SwiftData
import CryptoKit

private struct BackupTestFailure: Error, CustomStringConvertible {
    let description: String
}

#if !BACKUP_SIMULATOR_SMOKE
@main
#endif
@MainActor
struct ScopeBackupTests {
    static private(set) var skippedChecks: [String] = []
    private static let fileManager = FileManager.default
    private static let reviewState: [String: Date] = [
        "project_info": PersistenceFixtureValues.fixtureDate,
        "structural_system": PersistenceFixtureValues.fixtureDate.addingTimeInterval(30),
        "future_review_key": PersistenceFixtureValues.fixtureDate.addingTimeInterval(60)
    ]

    static func main() async {
        do {
            let root = try harnessRoot()
            try await run(at: root)
#if BACKUP_ARCHIVE_ONLY
            print("Scope backup archive checks passed (DTO fidelity, complete assets and archive validation only)")
#else
            print("Scope backup verification passed (DTO fidelity, complete assets, archive validation, fresh-store restore, conflicts and recovery)")
#endif
        } catch {
            // Only fixed assertion names and synthetic fixture errors reach this gate.
            FileHandle.standardError.write(Data("Scope backup verification failed: \(error)\n".utf8))
            exit(EXIT_FAILURE)
        }
    }

    static func run(at root: URL) async throws {
        skippedChecks = []
        let sourceSupport = root.appendingPathComponent("Source", isDirectory: true)
        let assetsRoot = sourceSupport.appendingPathComponent("ScopeAssets", isDirectory: true)
        let fixture = try makeFixture(assetsRoot: assetsRoot)
        let original = ScopeBackupRecord(scope: fixture, reviewState: reviewState)

        try testDTO(original)
        let archive = try ScopeBackupArchive.encode(records: [original], assetsRoot: assetsRoot)
        let contents = try ScopeBackupArchive.validate(data: archive)
        try require(contents.records.count == 1, "one exported scope")
        try require(contents.assets.count == 12, "all referenced, checklist and deterministic assets included")
        try require(!String(decoding: archive, as: UTF8.self).contains(sourceSupport.path), "archive has portable paths")
        try require(contents.assets.allSatisfy { SHA256.hash(data: $0.data).map { String(format: "%02x", $0) }.joined() == $0.sha256 }, "asset hashes")
        let archivedPaths = try Set(contents.records[0].referencedAssetPaths())
        try require(archivedPaths.isSubset(of: Set(contents.assets.map(\.path))), "all references are backed by archive bytes")
        try testArchiveRejections(archive, original: original, assetsRoot: assetsRoot, root: root)
        try testPortableCollisions(contents, root: root)
#if !BACKUP_ARCHIVE_ONLY
        try await testRestore(archive, original: original, contents: contents, root: root)
#endif
    }

    private static func testDTO(_ original: ScopeBackupRecord) throws {
        let expectedFields: Set<String> = [
            "id", "createdAt", "lastOpenedAt", "updatedAt", "status", "jobNumber", "scopeTitle",
            "jobTreadCustomer", "jobTreadJob", "jobTreadSync", "projectInfo", "existingConditions",
            "dimensions", "structuralSystem", "enclosure", "electrical", "drainage", "attachment",
            "documentsPayload", "finishes", "permitsHOA", "production", "customerApproval", "photos",
            "sketches", "voiceNotes", "aiExtractionDrafts", "reviewState"
        ]
        let fields = Set(Mirror(reflecting: original).children.compactMap(\.label))
        try require(expectedFields.isSubset(of: fields), "DTO covers every persisted root and review state")
        let decoded = try JSONDecoder().decode(ScopeBackupRecord.self, from: JSONEncoder().encode(original))
        try require(equivalent(decoded, original), "DTO roundtrip preserves hidden fields, whitespace, identifiers and metadata")
        let recreated = ScopeBackupRecord(scope: try decoded.makeScope(), reviewState: decoded.reviewState)
        try require(equivalent(recreated, original), "DTO recreates all root model values")

        var noncanonical = original
        noncanonical.structuralSystem?.notes = "  Structural note\n\n"
        noncanonical.structuralSystem?.postSize = "  Legacy post\n"
        noncanonical.enclosure?.screenEnclosureNotes = "  Screen note\n"
        noncanonical.existingConditions?.obstaclesNotes = "  Obstacle note\n"
        noncanonical.enclosure?.screenMeasurements = MeasurementsBlock(isEnabled: false, items: [])
        noncanonical.enclosure?.sunroomMeasurements = MeasurementsBlock(isEnabled: nil, items: nil)
        let exact = try JSONDecoder().decode(ScopeBackupRecord.self, from: JSONEncoder().encode(noncanonical))
        try require(equivalent(exact, noncanonical), "archive-only codec preserves values normalized by live Codable")
        try rejects("noncanonical DTO cannot silently normalize during model adoption") { _ = try exact.makeScope() }

        var malformed = original
        malformed.documentsPayload = Data("not-json".utf8)
        try rejects("malformed document payload reference inspection") { _ = try malformed.referencedAssetPaths() }
        try rejects("malformed document payload model recreation") { _ = try malformed.makeScope() }
        for raw in ["{\"unknownFutureDocument\":true}", "{\"irrigation\":null}"] {
            var unknown = original
            unknown.documentsPayload = Data(raw.utf8)
            try rejects("unsupported document payload cannot lose values") { _ = try unknown.referencedAssetPaths() }
        }
        var unknownAttachment = original
        var documentJSON = try JSONSerialization.jsonObject(with: unknownAttachment.documentsPayload!) as! [String: Any]
        var irrigation = documentJSON["irrigation"] as! [String: Any]
        irrigation["unknownFutureAttachment"] = "preserve or reject"
        documentJSON["irrigation"] = irrigation
        unknownAttachment.documentsPayload = try JSONSerialization.data(withJSONObject: documentJSON)
        try rejects("unsupported attachment member cannot be dropped") { _ = try unknownAttachment.referencedAssetPaths() }
        var reordered = original
        reordered.documentsPayload = try JSONSerialization.data(withJSONObject: JSONSerialization.jsonObject(with: original.documentsPayload!), options: [.prettyPrinted, .sortedKeys])
        try require(try reordered.referencedAssetPaths() == original.referencedAssetPaths(), "document JSON key order is immaterial")

        var remapping = original
        let before = remapping
        try rejects("incomplete path remapping") { try remapping.remapAssetPaths([:]) }
        try require(equivalent(remapping, before), "failed path remapping is atomic")
    }

    private static func testArchiveRejections(_ archive: Data, original: ScopeBackupRecord, assetsRoot: URL, root: URL) throws {
        try rejects("truncated archive") { _ = try ScopeBackupArchive.validate(data: Data(archive.prefix(25))) }
        for key in ["formatVersion", "schemaVersion"] {
            let changed = try mutate(archive) { $0[key] = 999_999 }
            try rejects("unsupported \(key)") { _ = try ScopeBackupArchive.validate(data: changed) }
        }
        let badHash = try mutateFirstAsset(archive) { $0["sha256"] = String(repeating: "0", count: 64) }
        try rejects("tampered asset hash") { _ = try ScopeBackupArchive.validate(data: badHash) }
        let badData = try mutateFirstAsset(archive) { $0["data"] = Data("tampered synthetic bytes".utf8).base64EncodedString() }
        try rejects("tampered asset bytes") { _ = try ScopeBackupArchive.validate(data: badData) }
        for path in ["../escape", "/tmp/escape", "assets/../escape", "assets/\(original.id.uuidString)/../escape", "assets/\(original.id.uuidString)/nested\\escape", "assets/\(original.id.uuidString)//escape"] {
            let traversal = try mutateFirstAsset(archive) { $0["path"] = path }
            try rejects("unsafe archive path") { _ = try ScopeBackupArchive.validate(data: traversal) }
        }
        let duplicate = try mutate(archive) { object in
            var assets = object["assets"] as! [[String: Any]]
            assets.append(assets[0])
            object["assets"] = assets
        }
        try rejects("duplicate archive asset path") { _ = try ScopeBackupArchive.validate(data: duplicate) }
        let missing = try mutate(archive) { object in
            object["assets"] = [] as [[String: Any]]
        }
        try rejects("missing referenced assets") { _ = try ScopeBackupArchive.validate(data: missing) }
        let duplicateScope = try mutate(archive) { object in
            var records = object["records"] as! [[String: Any]]
            records.append(records[0])
            object["records"] = records
        }
        try rejects("duplicate scope identifiers") { _ = try ScopeBackupArchive.validate(data: duplicateScope) }

        let caseCollision = try mutate(archive) { object in
            var assets = object["assets"] as! [[String: Any]]
            var copy = assets[0]
            let parts = (copy["path"] as! String).components(separatedBy: "/")
            copy["path"] = parts.dropLast().joined(separator: "/") + "/" + parts.last!.uppercased()
            assets.append(copy)
            object["assets"] = assets
        }
        try rejects("case-insensitive asset collision") { _ = try ScopeBackupArchive.validate(data: caseCollision) }
        let unicodeCollision = try mutate(archive) { object in
            var assets = object["assets"] as! [[String: Any]]
            let first = assets[0]
            let parent = ((first["path"] as! String) as NSString).deletingLastPathComponent
            for filename in ["caf\u{00E9}.jpg", "cafe\u{0301}.jpg"] {
                var copy = first
                copy["path"] = parent + "/" + filename
                assets.append(copy)
            }
            object["assets"] = assets
        }
        try rejects("Unicode-equivalent asset collision") { _ = try ScopeBackupArchive.validate(data: unicodeCollision) }
        let ancestorCollision = try mutate(archive) { object in
            var assets = object["assets"] as! [[String: Any]]
            var copy = assets[0]
            copy["path"] = (copy["path"] as! String) + "/child.jpg"
            assets.append(copy)
            object["assets"] = assets
        }
        try rejects("file directory ancestor collision") { _ = try ScopeBackupArchive.validate(data: ancestorCollision) }

        var missingReference = original
        var missingPhotos = missingReference.photos!
        missingPhotos[0].imagePath = assetsRoot.appendingPathComponent(original.id.uuidString).appendingPathComponent("absent.jpg").path
        missingReference.photos = missingPhotos
        try rejects("export missing file") { _ = try ScopeBackupArchive.encode(records: [missingReference], assetsRoot: assetsRoot) }

        var outsideReference = original
        var outsidePhotos = outsideReference.photos!
        let outside = root.appendingPathComponent("outside-fixture.jpg")
        try Data("outside synthetic image".utf8).write(to: outside)
        outsidePhotos[0].imagePath = outside.path
        outsideReference.photos = outsidePhotos
        try rejects("export reference outside scope") { _ = try ScopeBackupArchive.encode(records: [outsideReference], assetsRoot: assetsRoot) }

        let scopeDirectory = assetsRoot.appendingPathComponent(original.id.uuidString)
        let symlink = scopeDirectory.appendingPathComponent("symlink.jpg")
        try fileManager.createSymbolicLink(at: symlink, withDestinationURL: outside)
        try rejects("export symlink asset") { _ = try ScopeBackupArchive.encode(records: [original], assetsRoot: assetsRoot) }
        try fileManager.removeItem(at: symlink)
        let symlinkDirectory = scopeDirectory.appendingPathComponent("linked-directory")
        try fileManager.createSymbolicLink(at: symlinkDirectory, withDestinationURL: root)
        try rejects("export ancestor symlink") { _ = try ScopeBackupArchive.encode(records: [original], assetsRoot: assetsRoot) }
        try fileManager.removeItem(at: symlinkDirectory)
        let unreadable = scopeDirectory.appendingPathComponent("unreadable-owned-fixture", isDirectory: true)
        try fileManager.createDirectory(at: unreadable, withIntermediateDirectories: true)
        try Data("synthetic otherwise unreferenced checklist bytes".utf8).write(to: unreadable.appendingPathComponent("photo.jpg"))
        try fileManager.setAttributes([.posixPermissions: 0o000], ofItemAtPath: unreadable.path)
        do {
            defer { try? fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: unreadable.path) }
            if (try? fileManager.contentsOfDirectory(atPath: unreadable.path)) == nil {
                try rejects("unreadable managed directory cannot produce partial export") { _ = try ScopeBackupArchive.encode(records: [original], assetsRoot: assetsRoot) }
            } else {
                skippedChecks.append("unreadable-directory permission fixture: execution identity bypasses mode bits")
                print("SKIP: unreadable-directory permission fixture; this execution identity can bypass its mode bits")
            }
        }
        try fileManager.removeItem(at: unreadable)
        let oversized = scopeDirectory.appendingPathComponent("oversized-fixture.dat")
        try Data().write(to: oversized)
        let handle = try FileHandle(forWritingTo: oversized)
        try handle.truncate(atOffset: UInt64(ScopeBackupArchive.maximumAssetBytes + 1))
        try handle.close()
        try rejects("oversized managed asset") { _ = try ScopeBackupArchive.encode(records: [original], assetsRoot: assetsRoot) }
        try fileManager.removeItem(at: oversized)
        try require(try Data(contentsOf: outside) == Data("outside synthetic image".utf8), "unsafe export never changes external bytes")
    }

    // Recompute valid checksums so collision regressions cannot accidentally
    // pass merely because a mutated archive has an obsolete manifest.
    private struct ManifestFixture: Encodable {
        struct File: Encodable { let path: String; let size: Int; let sha256: String; let createdAt: Date?; let modifiedAt: Date? }
        let formatVersion: Int
        let schemaVersion: Int
        let createdAt: Date
        let records: [ScopeBackupRecord]
        let files: [File]
    }

    private static func checksummedArchive(_ input: ScopeBackupContents) throws -> Data {
        var contents = input
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let manifest = ManifestFixture(formatVersion: contents.formatVersion, schemaVersion: contents.schemaVersion, createdAt: contents.createdAt, records: contents.records, files: contents.assets.map {
            ManifestFixture.File(path: $0.path, size: $0.data.count, sha256: $0.sha256, createdAt: $0.createdAt, modifiedAt: $0.modifiedAt)
        })
        contents.manifestSHA256 = ScopeBackupArchive.digest(try encoder.encode(manifest))
        return try encoder.encode(contents)
    }

    private static func collisionArchive(_ input: ScopeBackupContents, names: [String]) throws -> Data {
        var contents = input
        for (index, name) in names.enumerated() {
            let bytes = Data("Distinct synthetic collision asset \(index)".utf8)
            contents.assets.append(ScopeBackupAsset(path: "assets/\(input.records[0].id.uuidString)/\(name)", data: bytes, sha256: ScopeBackupArchive.digest(bytes)))
        }
        return try checksummedArchive(contents)
    }

    private static func testPortableCollisions(_ contents: ScopeBackupContents, root: URL) throws {
        _ = try ScopeBackupArchive.validate(data: checksummedArchive(contents))
        let control = try collisionArchive(contents, names: ["distinct-a.dat", "distinct-b.dat"])
        try require(try ScopeBackupArchive.validate(data: control).assetCount == contents.assetCount + 2, "fresh valid collision-fixture manifests are accepted")
        for names in [
            ["ß.dat", "ss.dat"], ["Straße.dat", "STRASSE.dat"], ["ﬀ.dat", "ff.dat"],
            ["σ.dat", "ς.dat"], ["café.dat", "cafe\u{0301}.dat"],
            ["ß/first.dat", "ss/second.dat"], ["Folder/first.dat", "folder/second.dat"],
            ["ß", "ss/child.dat"]
        ] {
            let archive = try collisionArchive(contents, names: names)
            try rejects("checksummed filesystem-equivalent file/directory aliases") { _ = try ScopeBackupArchive.validate(data: archive) }
        }
        let directory = root.appendingPathComponent("ExclusiveWrites", isDirectory: true)
        try ScopeBackupFiles.makeDirectory(directory)
        let first = directory.appendingPathComponent("ß.dat")
        let second = directory.appendingPathComponent("ss.dat")
        let original = Data("preserve the first synthetic bytes".utf8)
        try ScopeBackupFiles.writeNew(original, to: first)
        try rejects("exclusive writer never replaces an exact existing file") { try ScopeBackupFiles.writeNew(Data("replacement".utf8), to: first) }
        // Lookup APIs and exclusive creation can disagree about Unicode aliases
        // on a simulator volume. Let O_EXCL decide, then assert byte preservation
        // in either supported outcome instead of predicting it with fileExists.
        do {
            try ScopeBackupFiles.writeNew(Data("separate bytes".utf8), to: second)
            try require(try Data(contentsOf: second) == Data("separate bytes".utf8), "distinct-volume alias retains its own bytes")
        } catch is ScopeBackupError { }
        try require(try Data(contentsOf: first) == original, "exclusive writer preserves original bytes")
    }

#if !BACKUP_ARCHIVE_ONLY
    private static func testRestore(_ archive: Data, original: ScopeBackupRecord, contents: ScopeBackupContents, root: URL) async throws {
        let archiveURL = root.appendingPathComponent("Synthetic.scopebackup")
        try archive.write(to: archiveURL)
        let support = root.appendingPathComponent("Destination", isDirectory: true)
        try fileManager.createDirectory(at: support, withIntermediateDirectories: true)
        let store = support.appendingPathComponent("Recovery.store")
        let container = try makeContainer(store)
        let reviewStore = SectionReviewStore(supportDirectory: support)
        let service = ScopeBackupService(container: container, reviewStore: reviewStore, supportDirectory: support)
        try service.recoverInterruptedRestores()
        let staged = try await service.stage(fileURL: archiveURL)
        try require(staged.records.count == 1 && staged.assetCount == 12, "staged preview counts")
        try require(try service.conflicts(in: staged).isEmpty, "fresh store has no conflicts")
        let result = try await service.restore(staged, policy: .skipExisting)
        try require(result.restoredCount == 1 && result.skippedCount == 0, "fresh restore result")
        try require(try fetch(container).count == 1, "fresh restore creates one local scope")
        var expected = contents.records[0]
        let mapping = Dictionary(uniqueKeysWithValues: contents.assets.map { item in
            (item.path, support.appendingPathComponent("ScopeAssets").appendingPathComponent(String(item.path.dropFirst("assets/".count))).path)
        })
        try expected.remapAssetPaths(mapping)
        let restored = try fetch(container)[0]
        let restoredReview = try reviewStore.backupReviewState(for: restored.id)
        try require(equivalent(ScopeBackupRecord(scope: restored, reviewState: restoredReview), expected), "restored fields, links, hidden measurements and paths")
        try verifyAssets(contents, support: support)
        try require(restoredReview == reviewState, "section review dates restored")
        try require(restored.jobTreadCustomer == original.jobTreadCustomer && restored.jobTreadSync == original.jobTreadSync, "JobTread references preserved without write actions")

        let exported = try await service.export(scopes: try fetch(container))
        let exportedContents = try ScopeBackupArchive.validate(data: Data(contentsOf: exported))
        try require(exportedContents.records.count == 1 && exportedContents.assetCount == 12, "service exports a complete restored scope")
        try require(exportedContents.records[0].reviewState == reviewState, "service export includes known and unknown review state")
        service.discardExport(fileURL: exported)

        let reopened = try makeContainer(store)
        let reopenReview = SectionReviewStore(supportDirectory: support)
        let reopenedScopes = try fetch(reopened)
        try require(reopenedScopes.count == 1, "fresh context/store reopen count")
        try require(equivalent(ScopeBackupRecord(scope: reopenedScopes[0], reviewState: try reopenReview.backupReviewState(for: original.id)), expected), "restored data and review survive reopen")

        let duplicateStage = try await service.stage(fileURL: archiveURL)
        try require(try service.conflicts(in: duplicateStage) == [original.id], "duplicate preview identifies exact conflict")
        let skipped = try await service.restore(duplicateStage, policy: .skipExisting)
        try require(skipped.restoredCount == 0 && skipped.skippedCount == 1, "repeat import defaults to skip")
        try require(try fetch(container).count == 1, "skip is idempotent")
        try require(equivalent(ScopeBackupRecord(scope: try fetch(container)[0], reviewState: try reviewStore.backupReviewState(for: original.id)), expected), "skip leaves original intact")

        let copyStage = try await service.stage(fileURL: archiveURL)
        let copied = try await service.restore(copyStage, policy: .keepBoth)
        try require(copied.restoredCount == 1 && copied.skippedCount == 0, "keep both imports a copy")
        let copies = try fetch(container)
        try require(copies.count == 2 && Set(copies.map(\.id)).count == 2, "keep both assigns a distinct scope ID")
        let clone = copies.first { $0.id != original.id }!
        try require(clone.photos?.first?.imagePath.contains(clone.id.uuidString) == true, "copy assets rebased to the new scope")
        try require(clone.jobTreadCustomer == original.jobTreadCustomer, "copy does not invent a customer ID")
        try require(try reviewStore.backupReviewState(for: clone.id) == reviewState, "copy review state remapped")
        try verifyAssets(contents, support: support)
        try verifyAssets(contents, support: support, scopeIDOverride: clone.id)

        let before = try fetch(container).count
        let badURL = root.appendingPathComponent("Corrupt.scopebackup")
        try Data("not an archive".utf8).write(to: badURL)
        do {
            _ = try await service.stage(fileURL: badURL)
            throw BackupTestFailure(description: "invalid staged import was accepted")
        } catch is BackupTestFailure {
            throw BackupTestFailure(description: "invalid staged import was accepted")
        } catch { }
        try require(try fetch(container).count == before, "invalid import adds no records")

        let canceled = try await service.stage(fileURL: archiveURL)
        service.discard(canceled)
        try require(try fetch(container).count == before, "canceling preview adds no records")
        try service.recoverInterruptedRestores()
        try require(try fetch(container).count == before, "recovery is harmless without a journal")
        try await testReviewedArchiveCannotBeSwapped(service: service, container: container, support: support, archiveURL: archiveURL, original: original, contents: contents, root: root)
        try testJournalRecovery(service: service, container: container, reviewStore: reviewStore, support: support, original: original, contents: contents)
        try await testReviewFailureRollback(service: service, container: container, support: support, archiveURL: archiveURL, contents: contents)
        try testMultipleReviewStores(support: support, scopeID: original.id)
        try await testStagingCleanup(service: service, support: support, archiveURL: archiveURL)
        let collisionURL = root.appendingPathComponent("UnicodeCollision.scopebackup")
        try collisionArchive(contents, names: ["ß.dat", "ss.dat"]).write(to: collisionURL)
        var collisionRejected = false
        do { _ = try await service.stage(fileURL: collisionURL) }
        catch { collisionRejected = true }
        try require(collisionRejected, "validly checksummed Unicode collision cannot enter restore preview")
        try require(try fetch(container).count == before, "Unicode collision adds no rows")
        try verifyAssets(contents, support: support)
        try verifyAssets(contents, support: support, scopeIDOverride: clone.id)
        try await testLargeReviewJournal(service: service, container: container, reviewStore: reviewStore, support: support, contents: contents, root: root)
    }

    private struct JournalFixture: Codable {
        let transactionID: UUID
        let scopeIDs: [UUID]
        let reviewStates: [String: [String: Date]]
    }

    private static func testReviewedArchiveCannotBeSwapped(service: ScopeBackupService, container: ModelContainer, support: URL, archiveURL: URL, original: ScopeBackupRecord, contents: ScopeBackupContents, root: URL) async throws {
        let stagingRoot = support.appendingPathComponent("ScopeBackupStaging", isDirectory: true)
        let beforeDirectories = Set((try? fileManager.contentsOfDirectory(atPath: stagingRoot.path)) ?? [])
        let stage = try await service.stage(fileURL: archiveURL)
        let afterDirectories = Set(try fileManager.contentsOfDirectory(atPath: stagingRoot.path))
        let created = afterDirectories.subtracting(beforeDirectories)
        try require(created.count == 1, "one private stage created for swap fixture")
        let stagedArchive = stagingRoot.appendingPathComponent(created.first!).appendingPathComponent("archive.scopebackup")

        let sourceAssets = root.appendingPathComponent("Source/ScopeAssets", isDirectory: true)
        let independentFile = sourceAssets.appendingPathComponent(original.id.uuidString).appendingPathComponent("customer-signature.drawing")
        let priorBytes = try Data(contentsOf: independentFile)
        defer { try? priorBytes.write(to: independentFile, options: .atomic) }
        try Data("different synthetic independent drawing bytes".utf8).write(to: independentFile, options: .atomic)
        let alternate = try ScopeBackupArchive.encode(records: [original], assetsRoot: sourceAssets)
        let alternateContents = try ScopeBackupArchive.validate(data: alternate)
        try require(alternateContents.records == contents.records, "swapped valid archive has identical scope metadata")
        try require(alternateContents.assets != contents.assets, "swapped valid archive changes only asset snapshot")
        try alternate.write(to: stagedArchive, options: .atomic)
        let before = try fetch(container).count
        var rejected = false
        do { _ = try await service.restore(stage, policy: .keepBoth) }
        catch { rejected = true }
        try require(rejected, "restore pins the exact reviewed archive asset snapshot")
        try require(try fetch(container).count == before, "swapped stage cannot create records")
        try verifyAssets(contents, support: support)
        service.discard(stage)
    }

    private static func testJournalRecovery(service: ScopeBackupService, container: ModelContainer, reviewStore: SectionReviewStore, support: URL, original: ScopeBackupRecord, contents: ScopeBackupContents) throws {
        let journal = support.appendingPathComponent("ScopeBackupRestoreJournal.json")
        let before = try fetch(container).count
        // Simulate interruption after the database commit but before journal retirement.
        // Review state was saved before that commit. A later user invalidation
        // must survive cleanup; replaying the journal would resurrect stale marks.
        try reviewStore.restoreReviewStates([original.id: reviewState])
        try JSONEncoder().encode(JournalFixture(transactionID: UUID(), scopeIDs: [original.id], reviewStates: [original.id.uuidString: reviewState])).write(to: journal)
        try reviewStore.restoreReviewStates([original.id: [:]])
        try service.recoverInterruptedRestores()
        try require(!fileManager.fileExists(atPath: journal.path), "committed journal retired")
        try require(try reviewStore.backupReviewState(for: original.id).isEmpty, "committed journal never resurrects subsequently cleared review marks")
        try verifyAssets(contents, support: support)
        try reviewStore.restoreReviewStates([original.id: reviewState])

        // Simulate interruption after file adoption and review save, before database commit.
        let orphanID = UUID()
        let orphan = support.appendingPathComponent("ScopeAssets").appendingPathComponent(orphanID.uuidString)
        try fileManager.createDirectory(at: orphan, withIntermediateDirectories: true)
        try Data("synthetic uncommitted import".utf8).write(to: orphan.appendingPathComponent("orphan.jpg"))
        try reviewStore.restoreReviewStates([orphanID: reviewState])
        try JSONEncoder().encode(JournalFixture(transactionID: UUID(), scopeIDs: [orphanID], reviewStates: [orphanID.uuidString: reviewState])).write(to: journal)
        try service.recoverInterruptedRestores()
        try require(!fileManager.fileExists(atPath: orphan.path), "uncommitted journal removes only its adopted asset directory")
        try require(try reviewStore.backupReviewState(for: orphanID).isEmpty, "uncommitted journal removes only its review marks")
        try require(try fetch(container).count == before, "journal rollback preserves unrelated records")
        try verifyAssets(contents, support: support)

        let bad = Data("corrupt synthetic restore journal".utf8)
        try bad.write(to: journal)
        try rejects("corrupt journal recovery fails closed") { try service.recoverInterruptedRestores() }
        try require(try Data(contentsOf: journal) == bad, "corrupt journal retained for investigation")
        try require(try fetch(container).count == before, "corrupt journal changes no records")
        try fileManager.removeItem(at: journal)
    }

    private static func testReviewFailureRollback(service: ScopeBackupService, container: ModelContainer, support: URL, archiveURL: URL, contents: ScopeBackupContents) async throws {
        let before = try fetch(container).count
        let stage = try await service.stage(fileURL: archiveURL)
        let sidecar = support.appendingPathComponent("WorkflowState/SectionReviewState.json")
        let original = try Data(contentsOf: sidecar)
        let corrupt = Data("synthetic corrupt review sidecar".utf8)
        try corrupt.write(to: sidecar, options: .atomic)
        var failed = false
        do { _ = try await service.restore(stage, policy: .keepBoth) }
        catch { failed = true }
        try require(failed, "review-write boundary failure rejects restore")
        try require(try fetch(container).count == before, "review failure commits no imported record")
        try require(try Data(contentsOf: sidecar) == corrupt, "failed restore never replaces the prior sidecar")
        let journal = try Data(contentsOf: support.appendingPathComponent("ScopeBackupRestoreJournal.json"))
        let object = try JSONSerialization.jsonObject(with: journal) as! [String: Any]
        try require(journal.count <= 64 * 1_024 && object["formatVersion"] as? Int == 2 && object["reviewStates"] == nil, "new recovery journal is bounded and contains IDs only")
        try verifyAssets(contents, support: support)
        // Repair only this synthetic sidecar, then prove interrupted recovery finishes.
        try original.write(to: sidecar, options: .atomic)
        try service.recoverInterruptedRestores()
        try require(!fileManager.fileExists(atPath: support.appendingPathComponent("ScopeBackupRestoreJournal.json").path), "repair permits journal recovery")
        try require(try fetch(container).count == before, "recovered failure preserves prior scopes")
        try verifyAssets(contents, support: support)
        service.discard(stage)
    }

    private static func testLargeReviewJournal(service: ScopeBackupService, container: ModelContainer, reviewStore: SectionReviewStore, support: URL, contents: ScopeBackupContents, root: URL) async throws {
        let hugeKey = String(repeating: "R", count: 8 * 1_024 * 1_024)
        let marks = [hugeKey: PersistenceFixtureValues.fixtureDate, "future_review_key": PersistenceFixtureValues.fixtureDate]
        var large = contents
        large.records[0].reviewState = marks
        let data = try checksummedArchive(large)
        _ = try ScopeBackupArchive.validate(data: data)
        let url = root.appendingPathComponent("LargeReview.scopebackup")
        try data.write(to: url)
        let before = Set(try fetch(container).map(\.id))
        let stage = try await service.stage(fileURL: url)
        let result = try await service.restore(stage, policy: .keepBoth)
        let newIDs = Set(try fetch(container).map(\.id)).subtracting(before)
        try require(result.restoredCount == 1 && newIDs.count == 1, "accepted large review key restores successfully")
        let id = newIDs.first!
        try require(try reviewStore.backupReviewState(for: id) == marks, "large review metadata preserved exactly")
        let journalURL = support.appendingPathComponent("ScopeBackupRestoreJournal.json")
        try require(!fileManager.fileExists(atPath: journalURL.path), "large review restore retires journal")
        try service.recoverInterruptedRestores()
        try verifyAssets(contents, support: support, scopeIDOverride: id)
        let reopened = try makeContainer(support.appendingPathComponent("Recovery.store"))
        try require(try fetch(reopened).count == before.count + 1, "large review restore persists after reopening")
        try require(try SectionReviewStore(supportDirectory: support).backupReviewState(for: id) == marks, "large review key survives fresh review store")

        let legacy = try JSONEncoder().encode(JournalFixture(transactionID: UUID(), scopeIDs: [id], reviewStates: [id.uuidString: marks]))
        try require(legacy.count > 8 * 1_024 * 1_024, "legacy fixture crosses old recovery read limit")
        try legacy.write(to: journalURL)
        try service.recoverInterruptedRestores()
        try require(try reviewStore.backupReviewState(for: id) == marks, "oversized committed legacy journal preserves current marks")
        try require(!fileManager.fileExists(atPath: journalURL.path), "oversized legacy journal retired")
        // Recovery must not resurrect marks cleared after the database commit.
        try legacy.write(to: journalURL)
        try reviewStore.restoreReviewStates([id: [:]])
        try service.recoverInterruptedRestores()
        try require(try reviewStore.backupReviewState(for: id).isEmpty, "oversized legacy journal never replays stale review keys")
        try reviewStore.restoreReviewStates([id: marks])

        let orphanID = UUID()
        let orphan = support.appendingPathComponent("ScopeAssets/\(orphanID.uuidString)")
        try ScopeBackupFiles.makeDirectory(orphan)
        try Data("synthetic uncommitted large-review asset".utf8).write(to: orphan.appendingPathComponent("orphan.dat"))
        try reviewStore.restoreReviewStates([orphanID: marks])
        try JSONEncoder().encode(JournalFixture(transactionID: UUID(), scopeIDs: [orphanID], reviewStates: [orphanID.uuidString: marks])).write(to: journalURL)
        try service.recoverInterruptedRestores()
        try require(!fileManager.fileExists(atPath: orphan.path), "oversized uncommitted legacy journal rolls back only registered files")
        try require(try reviewStore.backupReviewState(for: orphanID).isEmpty, "oversized uncommitted legacy journal clears its review state")
        try require(Set(try fetch(container).map(\.id)) == before.union([id]), "large journal recovery preserves all committed rows")
        try require(try reviewStore.backupReviewState(for: id) == marks, "large journal rollback preserves unrelated review metadata")
        try verifyAssets(contents, support: support)
        try verifyAssets(contents, support: support, scopeIDOverride: id)

        for invalid: [String: Any] in [
            ["formatVersion": 999, "transactionID": UUID().uuidString, "scopeIDs": [id.uuidString]],
            ["formatVersion": 2, "transactionID": UUID().uuidString, "scopeIDs": [id.uuidString], "padding": String(repeating: "x", count: 64 * 1_024)]
        ] {
            let bytes = try JSONSerialization.data(withJSONObject: invalid)
            try bytes.write(to: journalURL)
            try rejects("unsupported or oversized new journal fails closed") { try service.recoverInterruptedRestores() }
            try require(try Data(contentsOf: journalURL) == bytes, "invalid journal retained without mutation")
            try require(Set(try fetch(container).map(\.id)) == before.union([id]), "invalid journal changes no rows")
            try verifyAssets(contents, support: support, scopeIDOverride: id)
            try fileManager.removeItem(at: journalURL)
        }
        let maximumIDs = (0..<ScopeBackupArchive.maximumScopeCount).map { _ in UUID().uuidString }
        let maximumJournal = try JSONSerialization.data(withJSONObject: ["formatVersion": 2, "transactionID": UUID().uuidString, "scopeIDs": maximumIDs])
        try require(maximumJournal.count <= 64 * 1_024, "every allowed scope ID fits the compact journal bound")
        try maximumJournal.write(to: journalURL)
        try service.recoverInterruptedRestores()
        try require(!fileManager.fileExists(atPath: journalURL.path), "maximum-scope compact journal recovers")
        try require(Set(try fetch(container).map(\.id)) == before.union([id]), "maximum journal preserves committed rows")
        try require(try reviewStore.backupReviewState(for: id) == marks, "maximum journal preserves unrelated large review metadata")
        service.discard(stage)
    }

    private static func testMultipleReviewStores(support: URL, scopeID: UUID) throws {
        let first = SectionReviewStore(supportDirectory: support)
        let stale = SectionReviewStore(supportDirectory: support)
        let changed = ["electrical": PersistenceFixtureValues.fixtureDate.addingTimeInterval(90)]
        try first.restoreReviewStates([scopeID: changed])
        try require(try stale.backupReviewState(for: scopeID) == changed, "stale review instance reads newer disk marks")
        let other = UUID()
        try stale.restoreReviewStates([other: reviewState])
        try require(try first.backupReviewState(for: scopeID) == changed, "another instance restore preserves prior scope marks")
        try require(try first.backupReviewState(for: other) == reviewState, "another instance sees newly restored marks")
        try first.restoreReviewStates([scopeID: reviewState, other: [:]])
    }

    private static func testStagingCleanup(service: ScopeBackupService, support: URL, archiveURL: URL) async throws {
        let root = support.appendingPathComponent("ScopeBackupStaging", isDirectory: true)
        let abandoned = root.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let unrelated = root.appendingPathComponent(UUID().uuidString, isDirectory: true)
        for folder in [abandoned, unrelated] {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            try Data("synthetic workspace bytes".utf8).write(to: folder.appendingPathComponent("fixture.txt"))
        }
        try Data("Scopes backup workspace v1".utf8).write(to: abandoned.appendingPathComponent("workspace.marker"))
        let before = Set(try fileManager.contentsOfDirectory(atPath: root.path))
        let live = try await service.stage(fileURL: archiveURL)
        let created = Set(try fileManager.contentsOfDirectory(atPath: root.path)).subtracting(before)
        try require(created.count == 1, "live stage fixture directory identified")
        let liveDirectory = root.appendingPathComponent(created.first!)
        try service.recoverInterruptedRestores()
        try require(!fileManager.fileExists(atPath: abandoned.path), "startup retires marker-owned inactive workspace")
        try require(fileManager.fileExists(atPath: unrelated.appendingPathComponent("fixture.txt").path), "startup preserves unmarked workspace")
        try require(fileManager.fileExists(atPath: liveDirectory.appendingPathComponent("archive.scopebackup").path), "startup preserves another live preview")
        service.discard(live)
        try require(!fileManager.fileExists(atPath: liveDirectory.path), "discard releases only its own staged workspace")
    }
#endif

    private static func makeFixture(assetsRoot: URL) throws -> JobScope {
        let scope = PersistenceFixtureValues.makeBaselineScope()
        scope.structuralSystem = StructuralSystem(measurements: measurement("Structural hidden fixture", enabled: false), postSize: "Legacy post", notes: "Structural note")
        scope.enclosure = Enclosure(
            enclosureTypes: [.screenEnclosure],
            screenEnclosureNotes: "Screen note",
            screenMeasurements: measurement("Screen fixture", enabled: false),
            sunroomMeasurements: measurement("Sunroom hidden fixture", enabled: false)
        )
        let voiceID = UUID(uuidString: "DDDDDDDD-EEEE-FFFF-AAAA-BBBBBBBBBBBB")!
        scope.voiceNotes = [ScopeVoiceNote(id: voiceID, audioPath: "/sanitized/voice-note.m4a", transcript: "Synthetic transcript", transcriptStatus: .failed, transcriptErrorMessage: "Synthetic retry", durationSeconds: 9.5, createdAt: PersistenceFixtureValues.fixtureDate, updatedAt: PersistenceFixtureValues.fixtureDate)]
        scope.aiExtractionDrafts = [ScopeAIExtractionDraft(sourceVoiceNoteID: voiceID, status: .dismissed, summary: "Synthetic draft", suggestedFields: [ScopeAIFieldSuggestion(sectionKey: "structural_system", fieldKey: "notes", label: "Notes", proposedValue: "Synthetic suggestion", confidence: .low, isApplied: false)], remainingSectionKeys: ["electrical"])]
        var documents = scope.documents!
        documents.propertySurvey = DocumentAttachmentFile(originalFilename: "survey.pdf", filePath: "/sanitized/survey.pdf", contentTypeIdentifier: "com.adobe.pdf", source: .files)
        scope.documents = documents

        var record = ScopeBackupRecord(scope: scope, reviewState: reviewState)
        let sourcePaths = try record.referencedAssetPaths()
        try require(sourcePaths.count == 8, "fixture exercises every path category")
        let scopeRoot = assetsRoot.appendingPathComponent(scope.id.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: scopeRoot, withIntermediateDirectories: true)
        var mapping: [String: String] = [:]
        for (index, path) in sourcePaths.enumerated() {
            let url = scopeRoot.appendingPathComponent("reference-\(index)-\(URL(fileURLWithPath: path).lastPathComponent)")
            try Data("Synthetic asset bytes \(index)".utf8).write(to: url)
            mapping[path] = url.path
        }
        let independent = ["customer-signature.drawing", "salesperson-signature.drawing", "site-diagram.png", "ExistingConditionsChecklist/front_of_house/99999999-AAAA-BBBB-CCCC-DDDDDDDDDDDD__photo_library__fixture.jpg"]
        for name in independent {
            let url = scopeRoot.appendingPathComponent(name)
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data("Synthetic unreferenced deterministic/checklist asset \(name)".utf8).write(to: url)
        }
        // Checklist ordering and createdAt are derived from file metadata, not
        // SwiftData. Give every source file a distinct deterministic timestamp.
        let allFiles = try fileManager.subpathsOfDirectory(atPath: scopeRoot.path).sorted()
        for (index, relative) in allFiles.enumerated() {
            let url = scopeRoot.appendingPathComponent(relative)
            guard try url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else { continue }
            try fileManager.setAttributes([
                .creationDate: PersistenceFixtureValues.fixtureDate.addingTimeInterval(Double(index)),
                .modificationDate: PersistenceFixtureValues.fixtureDate.addingTimeInterval(100 + Double(index))
            ], ofItemAtPath: url.path)
        }
        try record.remapAssetPaths(mapping)
        return try record.makeScope()
    }

    private static func measurement(_ type: String, enabled: Bool) -> MeasurementsBlock {
        MeasurementsBlock(isEnabled: enabled, items: [MeasurementItem(type: "Other", customType: type, value: "approx 12' 6\"", notes: "  retain notes\n")])
    }

    private static func equivalent(_ lhs: ScopeBackupRecord, _ rhs: ScopeBackupRecord) -> Bool {
        var left = lhs
        var right = rhs
        let leftDocuments = lhs.documentsPayload.flatMap { try? JSONDecoder().decode(DocumentsSection.self, from: $0) }
        let rightDocuments = rhs.documentsPayload.flatMap { try? JSONDecoder().decode(DocumentsSection.self, from: $0) }
        left.documentsPayload = nil
        right.documentsPayload = nil
        return left == right && leftDocuments == rightDocuments
    }

    private static func verifyAssets(_ contents: ScopeBackupContents, support: URL, scopeIDOverride: UUID? = nil) throws {
        for asset in contents.assets {
            var relative = String(asset.path.dropFirst("assets/".count))
            if let scopeIDOverride {
                relative = scopeIDOverride.uuidString + "/" + relative.split(separator: "/", maxSplits: 1)[1]
            }
            let destination = support.appendingPathComponent("ScopeAssets").appendingPathComponent(relative)
            try require(try Data(contentsOf: destination) == asset.data, "restored asset byte fidelity")
            let attributes = try fileManager.attributesOfItem(atPath: destination.path)
            guard let createdAt = asset.createdAt, let modifiedAt = asset.modifiedAt,
                  let actualCreated = attributes[.creationDate] as? Date,
                  let actualModified = attributes[.modificationDate] as? Date else {
                throw BackupTestFailure(description: "restored asset timestamps missing")
            }
            try require(abs(actualCreated.timeIntervalSince(createdAt)) < 0.001, "restored file creation date/checklist order fidelity")
            try require(abs(actualModified.timeIntervalSince(modifiedAt)) < 0.001, "restored file modification date fidelity")
        }
    }

    private static func makeContainer(_ store: URL) throws -> ModelContainer {
        let schema = Schema([JobScope.self])
        let config = ModelConfiguration("BackupFixture", schema: schema, url: store, allowsSave: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private static func fetch(_ container: ModelContainer) throws -> [JobScope] {
        try ModelContext(container).fetch(FetchDescriptor<JobScope>())
    }

    private static func mutate(_ data: Data, _ change: (inout [String: Any]) -> Void) throws -> Data {
        var object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        change(&object)
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    private static func mutateFirstAsset(_ data: Data, _ change: (inout [String: Any]) -> Void) throws -> Data {
        try mutate(data) { object in
            var assets = object["assets"] as! [[String: Any]]
            change(&assets[0])
            object["assets"] = assets
        }
    }

    private static func rejects(_ label: String, _ operation: () throws -> Void) throws {
        do {
            try operation()
        } catch {
            return
        }
        throw BackupTestFailure(description: "expected rejection: \(label)")
    }

    private static func require(_ condition: @autoclosure () throws -> Bool, _ label: String) throws {
        guard try condition() else { throw BackupTestFailure(description: label) }
    }

    private static func harnessRoot() throws -> URL {
        guard CommandLine.arguments.count == 2 else { throw BackupTestFailure(description: "missing synthetic harness directory") }
        let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true).standardizedFileURL.resolvingSymlinksInPath()
        let tmp = URL(fileURLWithPath: "/tmp", isDirectory: true).resolvingSymlinksInPath()
        guard root.deletingLastPathComponent() == tmp,
              root.lastPathComponent.hasPrefix("scope-backup-tests."),
              fileManager.fileExists(atPath: root.appendingPathComponent(".scope-backup-harness").path) else {
            throw BackupTestFailure(description: "unsafe synthetic harness directory")
        }
        return root
    }
}
