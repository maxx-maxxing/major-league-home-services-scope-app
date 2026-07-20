import Combine
import Foundation
import OSLog

enum PersistenceSaveOperation: String, CaseIterable, Sendable {
    case autosave
    case manualFlush
    case createScope
    case renameScope
    case deleteScope
    case recordScopeAccess
    case hydrateLinkedCustomer
    case refreshLinkedCustomer
}

struct PersistenceSaveIssue: Identifiable, Equatable, Sendable {
    let id: UUID
    let operation: PersistenceSaveOperation
    let occurredAt: Date

    init(
        id: UUID = UUID(),
        operation: PersistenceSaveOperation,
        occurredAt: Date = .now
    ) {
        self.id = id
        self.operation = operation
        self.occurredAt = occurredAt
    }

    var title: String {
        "Changes Not Saved"
    }

    var message: String {
        "The app couldn’t confirm your latest changes were saved. Keep the app open and retry before closing it."
    }
}

@MainActor
final class PersistenceSaveHealth: ObservableObject {
    typealias SaveAction = @MainActor () throws -> Void

    @Published private(set) var issue: PersistenceSaveIssue?

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "ConstructionScopeApp",
        category: "PersistenceSaveHealth"
    )

    private var saveAction: SaveAction?
    private let now: () -> Date

    init(
        saveAction: SaveAction? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.saveAction = saveAction
        self.now = now
    }

    func configure(saveAction: @escaping SaveAction) {
        self.saveAction = saveAction
    }

    @discardableResult
    func attempt(_ operation: PersistenceSaveOperation) -> Bool {
        do {
            guard let saveAction else {
                throw SaveActionUnavailable()
            }

            try saveAction()
            issue = nil
            return true
        } catch {
            issue = PersistenceSaveIssue(operation: operation, occurredAt: now())
            Self.logger.error(
                "Local model save failed during operation: \(operation.rawValue, privacy: .public)"
            )
            return false
        }
    }

    @discardableResult
    func retry() -> Bool {
        guard let operation = issue?.operation else { return true }
        return attempt(operation)
    }
}

private struct SaveActionUnavailable: Error {}
