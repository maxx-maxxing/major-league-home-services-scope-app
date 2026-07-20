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
        testConfirmedActionRunsOnlyAfterSave()
        testConfirmedActionSurvivesFailedRetries()
        testLaterSuccessfulSaveDrainsAllQueuedActionsOnce()
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

    @MainActor
    private static func testConfirmedActionRunsOnlyAfterSave() {
        var events: [String] = []
        let health = PersistenceSaveHealth {
            events.append("save")
        }

        require(
            health.attempt(.manualFlush, afterConfirmedSave: { events.append("confirmed") }),
            "save with a confirmed action was reported as failed"
        )
        require(events == ["save", "confirmed"], "confirmed action did not run once after the save")
    }

    @MainActor
    private static func testConfirmedActionSurvivesFailedRetries() {
        var saveCount = 0
        var confirmedActionCount = 0
        var shouldFail = true
        let health = PersistenceSaveHealth {
            saveCount += 1
            if shouldFail {
                throw InjectedSaveFailure.rejected
            }
        }

        require(
            !health.attempt(.manualFlush, afterConfirmedSave: { confirmedActionCount += 1 }),
            "initial failing save with a confirmed action was reported as success"
        )
        require(confirmedActionCount == 0, "confirmed action ran after a failed save")
        require(!health.retry(), "still-failing retry was reported as success")
        require(confirmedActionCount == 0, "confirmed action ran after a failed retry")

        shouldFail = false
        require(health.retry(), "eventual successful retry was reported as failed")
        require(saveCount == 3, "confirmed-action retry path used the wrong save count")
        require(confirmedActionCount == 1, "successful retry did not run the retained action exactly once")
        require(health.issue == nil, "successful confirmed-action retry left a stale issue")
        require(health.retry(), "retry without an issue should remain a no-op success")
        require(confirmedActionCount == 1, "retained action ran more than once")
    }

    @MainActor
    private static func testLaterSuccessfulSaveDrainsAllQueuedActionsOnce() {
        var shouldFail = true
        var completed: [Int] = []
        let health = PersistenceSaveHealth {
            if shouldFail {
                throw InjectedSaveFailure.rejected
            }
        }

        require(
            !health.attempt(.manualFlush, afterConfirmedSave: { completed.append(1) }),
            "first queued action did not preserve the injected failure"
        )
        require(
            !health.attempt(.manualFlush, afterConfirmedSave: { completed.append(2) }),
            "second queued action did not preserve the injected failure"
        )
        require(completed.isEmpty, "queued actions ran before a confirmed save")

        shouldFail = false
        require(health.attempt(.autosave), "later ordinary save did not succeed")
        require(completed == [1, 2], "later successful save did not drain queued actions exactly once")
        require(health.attempt(.autosave), "second ordinary save did not succeed")
        require(completed == [1, 2], "drained actions ran again on a later save")
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
