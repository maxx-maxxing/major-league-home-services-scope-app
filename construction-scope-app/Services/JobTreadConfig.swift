import Foundation

enum JobTreadConfigError: LocalizedError, Sendable {
    case directAccessDisabled
    case missingValue(String)
    case unresolvedValue(String)
    case invalidBaseURL

    var errorDescription: String? {
        switch self {
        case .directAccessDisabled:
            return "JobTread lookup is unavailable in this build. Create a blank local scope and connect it later."
        case let .missingValue(key):
            return "JobTread configuration is missing `\(key)`."
        case let .unresolvedValue(key):
            return "JobTread configuration for `\(key)` is empty or unresolved."
        case .invalidBaseURL:
            return "JobTread configuration requires an absolute HTTPS API URL without credentials, query parameters, or a fragment."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .directAccessDisabled:
            return "Use the offline blank-scope workflow until an approved authenticated JobTread service is available."
        case .missingValue, .unresolvedValue, .invalidBaseURL:
            return "Check the ignored Debug-only JobTread override and app configuration wiring."
        }
    }
}

struct JobTreadConfig: Sendable {
    let apiKey: String
    let organizationID: String
    let baseURL: URL

    static var isDirectAccessEnabled: Bool {
#if DEBUG
        true
#else
        false
#endif
    }

    init(bundle: Bundle = .main) throws {
        guard Self.isDirectAccessEnabled else {
            throw JobTreadConfigError.directAccessDisabled
        }

        try self.init(values: [
            "JOBTREAD_API_KEY": bundle.object(forInfoDictionaryKey: "JOBTREAD_API_KEY") as? String ?? "",
            "JOBTREAD_ORG_ID": bundle.object(forInfoDictionaryKey: "JOBTREAD_ORG_ID") as? String ?? "",
            "JOBTREAD_API_BASE_URL": bundle.object(forInfoDictionaryKey: "JOBTREAD_API_BASE_URL") as? String ?? ""
        ])
    }

    init(values: [String: String]) throws {
        guard Self.isDirectAccessEnabled else {
            throw JobTreadConfigError.directAccessDisabled
        }

        apiKey = try JobTreadConfig.requiredValue(for: "JOBTREAD_API_KEY", in: values)
        organizationID = try JobTreadConfig.requiredValue(for: "JOBTREAD_ORG_ID", in: values)

        let baseURLString = try JobTreadConfig.requiredValue(for: "JOBTREAD_API_BASE_URL", in: values)
        guard let parsedURL = URL(string: baseURLString),
              parsedURL.scheme?.lowercased() == "https",
              parsedURL.host != nil,
              parsedURL.user == nil,
              parsedURL.password == nil,
              parsedURL.query == nil,
              parsedURL.fragment == nil else {
            throw JobTreadConfigError.invalidBaseURL
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

    private static func requiredValue(for key: String, in values: [String: String]) throws -> String {
        guard let rawValue = values[key] else {
            throw JobTreadConfigError.missingValue(key)
        }

        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty, !trimmedValue.contains("$(") else {
            throw JobTreadConfigError.unresolvedValue(key)
        }

        return trimmedValue
    }
}
