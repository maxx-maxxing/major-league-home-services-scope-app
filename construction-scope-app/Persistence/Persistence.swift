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

        pendingSaveTask = Task { [weak self] in
            guard let self else { return }

            let delayNanos = UInt64(self.delay * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delayNanos)

            guard !Task.isCancelled else { return }

            scope.updatedAt = .now
            self.saveNow(.autosave)
        }
    }

    @discardableResult
    func flush(
        scope: JobScope,
        afterConfirmedSave action: PersistenceSaveHealth.ConfirmedSaveAction? = nil
    ) -> Bool {
        pendingSaveTask?.cancel()
        scope.updatedAt = .now
        return saveNow(.manualFlush, afterConfirmedSave: action)
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

    private let fileManager: FileManager
    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.fileURL = Self.defaultFileURL(fileManager: fileManager)
        load()
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
        persist()
    }

    func invalidate(_ section: ScopeSection, in scope: JobScope) {
        guard var scopeSections = completedSectionsByScope[scope.id],
              scopeSections[section] != nil else {
            return
        }

        scopeSections[section] = nil
        completedSectionsByScope[scope.id] = scopeSections.isEmpty ? nil : scopeSections
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
            let payload = SectionReviewPayload(completedSectionsByScope: completedSectionsByScope)
            let data = try encoder.encode(payload)
            try data.write(to: fileURL, options: .atomic)
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
