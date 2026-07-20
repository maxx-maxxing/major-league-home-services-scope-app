import Darwin
import Foundation

private struct DocumentImportCoordinationTestFailure: Error, CustomStringConvertible {
    let description: String
}

@main
private enum DocumentImportCoordinationTests {
    private static let scopeID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    private static let siblingScopeID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    private static let firstRequestID = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
    private static let secondRequestID = UUID(uuidString: "20000000-0000-0000-0000-000000000002")!
    private static let thirdRequestID = UUID(uuidString: "30000000-0000-0000-0000-000000000003")!
    private static let firstRowID = UUID(uuidString: "40000000-0000-0000-0000-000000000004")!
    private static let secondRowID = UUID(uuidString: "50000000-0000-0000-0000-000000000005")!

    static func main() {
        do {
            try testExactCurrentRequestIsAdopted()
            try testSameTargetStaleRequestIsDiscarded()
            try testCrossTargetStaleRequestIsDiscarded()
            try testWrongScopeIsDiscarded()
            try testMissingTargetIsDiscarded()
            try testRequestIdentityDistinguishesOtherwiseIdenticalRequests()
            try testInvalidationHelpersDoNotClearNewerRequests()
            try testInvalidatedRequestCannotAdopt()
            try testDuplicateCompletionCannotAdoptTwice()
            try testDecisionHelpersExposeOnlyTheirAssociatedValue()
            print("Document import coordination tests passed")
        } catch let failure as DocumentImportCoordinationTestFailure {
            fail(failure.description)
        } catch {
            fail("unexpected test failure type: \(String(describing: type(of: error)))")
        }
    }

    private static func testExactCurrentRequestIsAdopted() throws {
        var coordination = DocumentImportCoordination()
        let target = DocumentSlotTarget.additional(firstRowID)
        let request = coordination.beginRequest(
            id: firstRequestID,
            scopeID: scopeID,
            target: target
        )

        let decision = coordination.completionDecision(
            for: request,
            currentScopeID: scopeID,
            targetExists: { $0 == target }
        )
        try require(decision == .adopt(target), "exact current request was not adopted")
        try require(coordination.isCurrent(request), "pure decision unexpectedly invalidated the request")

        let resolvedDecision = coordination.resolveCompletion(
            for: request,
            currentScopeID: scopeID,
            targetExists: { $0 == target }
        )
        try require(resolvedDecision == .adopt(target), "resolved current request was not adopted")
        try require(coordination.activeRequest == nil, "resolved current request remained active")
    }

    private static func testSameTargetStaleRequestIsDiscarded() throws {
        var coordination = DocumentImportCoordination()
        let staleRequest = coordination.beginRequest(
            id: firstRequestID,
            scopeID: scopeID,
            target: .irrigation
        )
        let currentRequest = coordination.beginRequest(
            id: secondRequestID,
            scopeID: scopeID,
            target: .irrigation
        )

        let decision = coordination.resolveCompletion(
            for: staleRequest,
            currentScopeID: scopeID,
            targetExists: { _ in true }
        )
        try require(decision == .discard(.staleRequest), "same-target stale request was not discarded")
        try require(coordination.isCurrent(currentRequest), "stale completion cleared the current same-target request")
    }

    private static func testCrossTargetStaleRequestIsDiscarded() throws {
        var coordination = DocumentImportCoordination()
        let staleRequest = coordination.beginRequest(
            id: firstRequestID,
            scopeID: scopeID,
            target: .propertySurvey
        )
        let currentRequest = coordination.beginRequest(
            id: secondRequestID,
            scopeID: scopeID,
            target: .additional(secondRowID)
        )

        let decision = coordination.resolveCompletion(
            for: staleRequest,
            currentScopeID: scopeID,
            targetExists: { _ in true }
        )
        try require(decision == .discard(.staleRequest), "cross-target stale request was not discarded")
        try require(coordination.isCurrent(currentRequest), "stale completion cleared the current cross-target request")
    }

    private static func testWrongScopeIsDiscarded() throws {
        var coordination = DocumentImportCoordination()
        let request = coordination.beginRequest(
            id: firstRequestID,
            scopeID: scopeID,
            target: .irrigation
        )

        let decision = coordination.resolveCompletion(
            for: request,
            currentScopeID: siblingScopeID,
            targetExists: { _ in true }
        )
        try require(decision == .discard(.wrongScope), "wrong-scope completion was not discarded")
        try require(coordination.activeRequest == nil, "terminal wrong-scope completion remained active")
    }

    private static func testMissingTargetIsDiscarded() throws {
        var coordination = DocumentImportCoordination()
        let request = coordination.beginRequest(
            id: firstRequestID,
            scopeID: scopeID,
            target: .additional(firstRowID)
        )

        let decision = coordination.resolveCompletion(
            for: request,
            currentScopeID: scopeID,
            targetExists: { _ in false }
        )
        try require(decision == .discard(.missingTarget), "missing-target completion was not discarded")
        try require(coordination.activeRequest == nil, "terminal missing-target completion remained active")
    }

    private static func testRequestIdentityDistinguishesOtherwiseIdenticalRequests() throws {
        let first = DocumentImportRequest(
            id: firstRequestID,
            scopeID: scopeID,
            target: .additional(firstRowID)
        )
        let second = DocumentImportRequest(
            id: secondRequestID,
            scopeID: scopeID,
            target: .additional(firstRowID)
        )

        try require(first != second, "request identity ignored distinct request IDs")
        try require(first.id == firstRequestID, "request did not preserve its fixed identity")
        try require(second.id == secondRequestID, "replacement request did not preserve its fixed identity")
    }

    private static func testInvalidationHelpersDoNotClearNewerRequests() throws {
        var coordination = DocumentImportCoordination()
        let staleRequest = coordination.beginRequest(
            id: firstRequestID,
            scopeID: scopeID,
            target: .irrigation
        )
        let currentRequest = coordination.beginRequest(
            id: thirdRequestID,
            scopeID: scopeID,
            target: .propertySurvey
        )

        try require(!coordination.invalidate(staleRequest), "stale request invalidation unexpectedly succeeded")
        try require(coordination.isCurrent(currentRequest), "stale invalidation cleared the current request")
        try require(coordination.invalidate(currentRequest), "current request invalidation failed")
        try require(coordination.activeRequest == nil, "invalidated current request remained active")

        let replacement = coordination.beginRequest(
            id: secondRequestID,
            scopeID: scopeID,
            target: .additional(secondRowID)
        )
        try require(
            coordination.invalidateActiveRequest() == replacement,
            "active invalidation did not return the invalidated request"
        )
        try require(coordination.invalidateActiveRequest() == nil, "empty invalidation did not return nil")
    }

    private static func testInvalidatedRequestCannotAdopt() throws {
        var coordination = DocumentImportCoordination()
        let request = coordination.beginRequest(
            id: firstRequestID,
            scopeID: scopeID,
            target: .additional(firstRowID)
        )

        try require(coordination.invalidate(request), "current request could not be invalidated")
        let lateDecision = coordination.resolveCompletion(
            for: request,
            currentScopeID: scopeID,
            targetExists: { _ in true }
        )
        try require(
            lateDecision == .discard(.staleRequest),
            "invalidated request was allowed to adopt after clear, removal, or disappearance"
        )
    }

    private static func testDuplicateCompletionCannotAdoptTwice() throws {
        var coordination = DocumentImportCoordination()
        let request = coordination.beginRequest(
            id: firstRequestID,
            scopeID: scopeID,
            target: .propertySurvey
        )

        let firstDecision = coordination.resolveCompletion(
            for: request,
            currentScopeID: scopeID,
            targetExists: { _ in true }
        )
        let duplicateDecision = coordination.resolveCompletion(
            for: request,
            currentScopeID: scopeID,
            targetExists: { _ in true }
        )
        try require(firstDecision == .adopt(.propertySurvey), "first completion did not adopt")
        try require(
            duplicateDecision == .discard(.staleRequest),
            "duplicate completion was allowed to adopt twice"
        )
    }

    private static func testDecisionHelpersExposeOnlyTheirAssociatedValue() throws {
        let adoptedTarget = DocumentSlotTarget.additional(firstRowID)
        let adoption = DocumentImportCompletionDecision.adopt(adoptedTarget)
        try require(adoption.adoptionTarget == adoptedTarget, "adoption helper lost its target")
        try require(adoption.discardReason == nil, "adoption exposed a discard reason")

        let discard = DocumentImportCompletionDecision.discard(.missingTarget)
        try require(discard.adoptionTarget == nil, "discard exposed an adoption target")
        try require(discard.discardReason == .missingTarget, "discard helper lost its reason")
    }

    private static func require(
        _ condition: @autoclosure () -> Bool,
        _ message: String
    ) throws {
        guard condition() else {
            throw DocumentImportCoordinationTestFailure(description: message)
        }
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("Document import coordination test failed: \(message)\n".utf8))
        Darwin.exit(1)
    }
}
