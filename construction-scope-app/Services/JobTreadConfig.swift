import Foundation

enum JobTreadConfigError: LocalizedError, Sendable {
    case missingValue(String)
    case unresolvedValue(String)
    case invalidBaseURL(String)

    var errorDescription: String? {
        switch self {
        case let .missingValue(key):
            return "JobTread configuration is missing `\(key)`."
        case let .unresolvedValue(key):
            return "JobTread configuration for `\(key)` is empty or unresolved."
        case let .invalidBaseURL(value):
            return "JobTread configuration contains an invalid API base URL: `\(value)`."
        }
    }

    var recoverySuggestion: String? {
        "Check the app target Info.plist values and xcconfig wiring for the current build configuration."
    }
}

struct JobTreadConfig {
    let apiKey: String
    let organizationID: String
    let baseURL: URL

    init(bundle: Bundle = .main) throws {
        apiKey = try JobTreadConfig.requiredValue(for: "JOBTREAD_API_KEY", in: bundle)
        organizationID = try JobTreadConfig.requiredValue(for: "JOBTREAD_ORG_ID", in: bundle)

        let baseURLString = try JobTreadConfig.requiredValue(for: "JOBTREAD_API_BASE_URL", in: bundle)
        guard let parsedURL = URL(string: baseURLString),
              let scheme = parsedURL.scheme?.lowercased(),
              ["https", "http"].contains(scheme),
              parsedURL.host != nil else {
            throw JobTreadConfigError.invalidBaseURL(baseURLString)
        }

        baseURL = parsedURL
    }

    static func load(bundle: Bundle = .main) -> Result<Self, JobTreadConfigError> {
        do {
            return .success(try Self(bundle: bundle))
        } catch let error as JobTreadConfigError {
            return .failure(error)
        } catch {
            return .failure(.missingValue("unknown"))
        }
    }

    private static func requiredValue(for key: String, in bundle: Bundle) throws -> String {
        guard let rawValue = bundle.object(forInfoDictionaryKey: key) as? String else {
            throw JobTreadConfigError.missingValue(key)
        }

        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty, !trimmedValue.contains("$(") else {
            throw JobTreadConfigError.unresolvedValue(key)
        }

        return trimmedValue
    }
}
