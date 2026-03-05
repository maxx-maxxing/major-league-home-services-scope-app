import Foundation
import SwiftUI
import SwiftData

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    private init(inMemory: Bool = false) {
        let schema = Schema([JobScope.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
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
