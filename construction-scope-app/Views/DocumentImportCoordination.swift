import Foundation

enum DocumentSlotTarget: Hashable, Identifiable, Sendable {
    case irrigation
    case propertySurvey
    case additional(UUID)

    var id: String {
        switch self {
        case .irrigation:
            return "irrigation"
        case .propertySurvey:
            return "propertySurvey"
        case .additional(let rowID):
            return "additional-\(rowID.uuidString)"
        }
    }
}

struct DocumentImportRequest: Equatable, Sendable {
    let id: UUID
    let scopeID: UUID
    let target: DocumentSlotTarget

    init(
        id: UUID = UUID(),
        scopeID: UUID,
        target: DocumentSlotTarget
    ) {
        self.id = id
        self.scopeID = scopeID
        self.target = target
    }
}

enum DocumentImportDiscardReason: Equatable, Sendable {
    case staleRequest
    case wrongScope
    case missingTarget
}

enum DocumentImportCompletionDecision: Equatable, Sendable {
    case adopt(DocumentSlotTarget)
    case discard(DocumentImportDiscardReason)

    var adoptionTarget: DocumentSlotTarget? {
        guard case .adopt(let target) = self else { return nil }
        return target
    }

    var discardReason: DocumentImportDiscardReason? {
        guard case .discard(let reason) = self else { return nil }
        return reason
    }
}

struct DocumentImportCoordination: Sendable {
    private(set) var activeRequest: DocumentImportRequest?

    init(activeRequest: DocumentImportRequest? = nil) {
        self.activeRequest = activeRequest
    }

    @discardableResult
    mutating func beginRequest(
        id: UUID = UUID(),
        scopeID: UUID,
        target: DocumentSlotTarget
    ) -> DocumentImportRequest {
        let request = DocumentImportRequest(
            id: id,
            scopeID: scopeID,
            target: target
        )
        activeRequest = request
        return request
    }

    func isCurrent(_ request: DocumentImportRequest) -> Bool {
        activeRequest == request
    }

    func completionDecision(
        for request: DocumentImportRequest,
        currentScopeID: UUID,
        targetExists: (DocumentSlotTarget) -> Bool
    ) -> DocumentImportCompletionDecision {
        guard isCurrent(request) else {
            return .discard(.staleRequest)
        }
        guard request.scopeID == currentScopeID else {
            return .discard(.wrongScope)
        }
        guard targetExists(request.target) else {
            return .discard(.missingTarget)
        }
        return .adopt(request.target)
    }

    @discardableResult
    mutating func resolveCompletion(
        for request: DocumentImportRequest,
        currentScopeID: UUID,
        targetExists: (DocumentSlotTarget) -> Bool
    ) -> DocumentImportCompletionDecision {
        let decision = completionDecision(
            for: request,
            currentScopeID: currentScopeID,
            targetExists: targetExists
        )
        if isCurrent(request) {
            activeRequest = nil
        }
        return decision
    }

    @discardableResult
    mutating func invalidate(_ request: DocumentImportRequest) -> Bool {
        guard isCurrent(request) else { return false }
        activeRequest = nil
        return true
    }

    @discardableResult
    mutating func invalidateActiveRequest() -> DocumentImportRequest? {
        defer { activeRequest = nil }
        return activeRequest
    }
}
