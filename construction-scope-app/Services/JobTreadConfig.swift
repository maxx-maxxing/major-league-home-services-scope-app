import Foundation

struct JobTreadConfig {
    let apiKey: String
    let organizationID: String
    let baseURL: URL

    init(bundle: Bundle = .main) {
        apiKey = JobTreadConfig.requiredValue(for: "JOBTREAD_API_KEY", in: bundle)
        organizationID = JobTreadConfig.requiredValue(for: "JOBTREAD_ORG_ID", in: bundle)

        let baseURLString = JobTreadConfig.requiredValue(for: "JOBTREAD_API_BASE_URL", in: bundle)
        guard let parsedURL = URL(string: baseURLString),
              let scheme = parsedURL.scheme?.lowercased(),
              ["https", "http"].contains(scheme),
              parsedURL.host != nil else {
            fatalError("Missing or invalid Info.plist value for JOBTREAD_API_BASE_URL. Expected a full URL to the JobTread Pave endpoint.")
        }

        baseURL = parsedURL
    }

    static let current = JobTreadConfig()

    private static func requiredValue(for key: String, in bundle: Bundle) -> String {
        guard let rawValue = bundle.object(forInfoDictionaryKey: key) as? String else {
            fatalError("Missing Info.plist value for \(key). Check the app target Info settings and xcconfig wiring.")
        }

        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty, !trimmedValue.contains("$(") else {
            fatalError("Missing or unresolved Info.plist value for \(key). Check the app target Info settings and xcconfig wiring.")
        }

        return trimmedValue
    }
}
