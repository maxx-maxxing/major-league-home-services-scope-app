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
    private var modelContext: ModelContext?
    private var pendingSaveTask: Task<Void, Never>?
    private let delay: TimeInterval

    init(delay: TimeInterval = 0.8) {
        self.delay = delay
    }

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func scheduleSave(for scope: JobScope) {
        pendingSaveTask?.cancel()

        pendingSaveTask = Task { [weak self] in
            guard let self else { return }

            let delayNanos = UInt64(self.delay * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delayNanos)

            guard !Task.isCancelled else { return }

            scope.updatedAt = .now
            do {
                try self.modelContext?.save()
            } catch {
                assertionFailure("Autosave failed: \(error)")
            }
        }
    }

    func flush(scope: JobScope) {
        pendingSaveTask?.cancel()
        scope.updatedAt = .now

        do {
            try modelContext?.save()
        } catch {
            assertionFailure("Manual save failed: \(error)")
        }
    }
}
