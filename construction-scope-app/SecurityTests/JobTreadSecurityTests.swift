import Foundation

private struct SecurityTestFailure: Error, CustomStringConvertible {
    let description: String
}

@main
private enum JobTreadSecurityTests {
    private static let validValues = [
        "JOBTREAD_API_KEY": "JT_SECRET_SENTINEL_7E5A1C",
        "JOBTREAD_ORG_ID": "JT_ORG_SENTINEL_7E5A1C",
        "JOBTREAD_API_BASE_URL": "https://jt-sentinel.invalid/pave"
    ]

    static func main() throws {
#if DEBUG
        try testDebugConfigurationValidation()
#else
        try testReleaseConfigurationIsDisabled()
#endif
        try testClientErrorsDoNotContainResponseContent()
        print("JobTread security tests passed")
    }

#if DEBUG
    private static func testDebugConfigurationValidation() throws {
        try require(JobTreadConfig.isDirectAccessEnabled, "Debug direct access should be enabled")

        let config = try JobTreadConfig(values: validValues)
        try require(config.apiKey == validValues["JOBTREAD_API_KEY"], "Debug grant did not load")
        try require(config.organizationID == validValues["JOBTREAD_ORG_ID"], "Debug organization did not load")
        try require(config.baseURL.absoluteString == validValues["JOBTREAD_API_BASE_URL"], "Debug HTTPS URL did not load")

        var missing = validValues
        missing.removeValue(forKey: "JOBTREAD_API_KEY")
        let missingError = try expectedConfigError(values: missing)
        guard case .missingValue("JOBTREAD_API_KEY") = missingError else {
            throw SecurityTestFailure(description: "Missing Debug grant was not rejected")
        }

        var empty = validValues
        empty["JOBTREAD_API_KEY"] = "   "
        let emptyError = try expectedConfigError(values: empty)
        guard case .unresolvedValue("JOBTREAD_API_KEY") = emptyError else {
            throw SecurityTestFailure(description: "Empty Debug grant was not rejected")
        }

        var unresolved = validValues
        unresolved["JOBTREAD_API_KEY"] = "$(JOBTREAD_API_KEY)"
        let unresolvedError = try expectedConfigError(values: unresolved)
        guard case .unresolvedValue("JOBTREAD_API_KEY") = unresolvedError else {
            throw SecurityTestFailure(description: "Unresolved Debug grant was not rejected")
        }

        let unsafeURLs = [
            "http://jt-sentinel.invalid/pave",
            "https://user:password@jt-sentinel.invalid/pave",
            "https://jt-sentinel.invalid/pave?token=secret",
            "https://jt-sentinel.invalid/pave#fragment"
        ]
        var validationErrors = [missingError, emptyError, unresolvedError]
        for unsafeURL in unsafeURLs {
            var values = validValues
            values["JOBTREAD_API_BASE_URL"] = unsafeURL
            let error = try expectedConfigError(values: values)
            guard case .invalidBaseURL = error else {
                throw SecurityTestFailure(description: "Unsafe Debug URL was not rejected")
            }
            validationErrors.append(error)
        }

        let sensitiveMarkers = Array(validValues.values) + unsafeURLs
        for error in validationErrors {
            let text = [error.errorDescription, error.recoverySuggestion]
                .compactMap { $0 }
                .joined(separator: " ")
            for marker in sensitiveMarkers {
                try require(!text.contains(marker), "Configuration error echoed a sensitive value")
            }
        }
    }

    private static func expectedConfigError(values: [String: String]) throws -> JobTreadConfigError {
        do {
            _ = try JobTreadConfig(values: values)
            throw SecurityTestFailure(description: "Unsafe configuration unexpectedly succeeded")
        } catch let error as JobTreadConfigError {
            return error
        }
    }
#else
    private static func testReleaseConfigurationIsDisabled() throws {
        try require(!JobTreadConfig.isDirectAccessEnabled, "Release direct access should be disabled")

        do {
            _ = try JobTreadConfig(values: validValues)
            throw SecurityTestFailure(description: "Release accepted injected direct credentials")
        } catch JobTreadConfigError.directAccessDisabled {
            // Expected.
        }

        do {
            _ = try JobTreadConfig()
            throw SecurityTestFailure(description: "Release loaded direct credentials from its bundle")
        } catch JobTreadConfigError.directAccessDisabled {
            // Expected.
        }
    }
#endif

    private static func testClientErrorsDoNotContainResponseContent() throws {
        let errors: [JobTreadClientError] = [
            .unexpectedStatusCode(500),
            .apiErrors(2)
        ]
        let sensitiveMarkers = Array(validValues.values) + ["customer@example.invalid", "raw response body"]

        for error in errors {
            let text = error.errorDescription ?? ""
            for marker in sensitiveMarkers {
                try require(!text.contains(marker), "Client error echoed response or customer content")
            }
        }
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else {
            throw SecurityTestFailure(description: message)
        }
    }
}
