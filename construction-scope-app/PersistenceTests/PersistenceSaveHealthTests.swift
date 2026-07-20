import Foundation

private enum InjectedSaveFailure: Error {
    case rejected
}

@main
struct PersistenceSaveHealthTests {
    @MainActor
    static func main() {
        testSuccessfulSaveHasNoIssue()
        testFailureIsPrivacySafeAndPersistsAcrossFailedRetry()
        testSuccessfulRetryClearsIssue()
        print("Persistence save health verification passed")
    }

    @MainActor
    private static func testSuccessfulSaveHasNoIssue() {
        var saveCount = 0
        let health = PersistenceSaveHealth {
            saveCount += 1
        }

        require(health.attempt(.autosave), "successful save was reported as failed")
        require(saveCount == 1, "successful save action did not run exactly once")
        require(health.issue == nil, "successful save left a stale issue")
        require(health.retry(), "retry without an issue should be a no-op success")
        require(saveCount == 1, "retry without an issue unexpectedly saved again")
    }

    @MainActor
    private static func testFailureIsPrivacySafeAndPersistsAcrossFailedRetry() {
        let sensitiveFailureText = "customer-123 /private/store/path"
        var saveCount = 0
        let health = PersistenceSaveHealth(
            saveAction: {
                saveCount += 1
                throw NSError(
                    domain: sensitiveFailureText,
                    code: 17,
                    userInfo: [NSLocalizedDescriptionKey: sensitiveFailureText]
                )
            },
            now: { Date(timeIntervalSince1970: 123) }
        )

        require(!health.attempt(.renameScope), "injected failure was reported as success")
        let firstIssue = requireIssue(health.issue, "injected failure did not publish an issue")
        require(firstIssue.operation == .renameScope, "failure recorded the wrong operation")
        require(firstIssue.occurredAt == Date(timeIntervalSince1970: 123), "failure timestamp was not injected deterministically")
        require(firstIssue.title == "Changes Not Saved", "issue title does not match the presented warning")
        require(
            firstIssue.message == "The app couldn’t confirm your latest changes were saved. Keep the app open and retry before closing it.",
            "issue message does not match the presented warning"
        )
        require(!firstIssue.title.contains(sensitiveFailureText), "issue title exposed underlying error text")
        require(!firstIssue.message.contains(sensitiveFailureText), "issue message exposed underlying error text")

        require(!health.retry(), "still-failing retry was reported as success")
        require(saveCount == 2, "failed retry did not invoke the save action")
        require(health.issue != nil, "failed retry cleared the persistent issue")
        require(health.issue?.operation == .renameScope, "failed retry changed the recorded operation")
    }

    @MainActor
    private static func testSuccessfulRetryClearsIssue() {
        var saveCount = 0
        let health = PersistenceSaveHealth {
            saveCount += 1
            if saveCount == 1 {
                throw InjectedSaveFailure.rejected
            }
        }

        require(!health.attempt(.deleteScope), "first injected save failure was reported as success")
        require(health.issue != nil, "first injected save failure did not publish an issue")
        require(health.retry(), "successful retry was reported as failed")
        require(saveCount == 2, "successful retry did not invoke the existing save action")
        require(health.issue == nil, "successful retry did not clear the issue")
    }

    private static func requireIssue(
        _ issue: PersistenceSaveIssue?,
        _ message: String
    ) -> PersistenceSaveIssue {
        guard let issue else {
            fail(message)
        }
        return issue
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            fail(message)
        }
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("Persistence save health verification failed: \(message)\n".utf8))
        Foundation.exit(1)
    }
}
