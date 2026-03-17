import Foundation

enum JobTreadClientError: LocalizedError {
    case invalidResponse
    case unexpectedStatusCode(Int, body: String)
    case apiErrors([String])
    case emptyCurrentGrant

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "JobTread returned an invalid response."
        case let .unexpectedStatusCode(statusCode, body):
            return "JobTread request failed with HTTP \(statusCode). Response: \(body)"
        case let .apiErrors(messages):
            return "JobTread returned API errors: \(messages.joined(separator: " | "))"
        case .emptyCurrentGrant:
            return "JobTread returned an empty currentGrant payload."
        }
    }
}

struct JobTreadCurrentGrant: Decodable, Sendable {
    let id: String
    let user: JobTreadUser
}

struct JobTreadUser: Decodable, Sendable {
    let id: String
    let name: String
    let memberships: JobTreadMembershipConnection
}

struct JobTreadMembershipConnection: Decodable, Sendable {
    let nodes: [JobTreadMembership]
}

struct JobTreadMembership: Decodable, Sendable {
    let organization: JobTreadOrganization
}

struct JobTreadOrganization: Decodable, Sendable {
    let id: String
    let name: String
}

struct JobTreadClient {
    private let session: URLSession
    private let config: JobTreadConfig
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        config: JobTreadConfig = .current,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.config = config
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }

    func fetchCurrentGrant() async throws -> JobTreadCurrentGrant {
        let requestBody = JobTreadCurrentGrantRequest(grantKey: config.apiKey)
        var request = URLRequest(url: config.baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw JobTreadClientError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
            throw JobTreadClientError.unexpectedStatusCode(httpResponse.statusCode, body: body)
        }

        let envelope = try decoder.decode(JobTreadCurrentGrantEnvelope.self, from: data)
        if !envelope.errors.isEmpty {
            throw JobTreadClientError.apiErrors(envelope.errors.map(\.message))
        }

        guard let currentGrant = envelope.currentGrant else {
            throw JobTreadClientError.emptyCurrentGrant
        }

        return currentGrant
    }
}

private struct JobTreadCurrentGrantRequest: Encodable {
    let query: JobTreadCurrentGrantQuery

    init(grantKey: String) {
        query = JobTreadCurrentGrantQuery(grantKey: grantKey)
    }
}

private struct JobTreadCurrentGrantQuery: Encodable {
    let context: JobTreadGrantContext
    let currentGrant: JobTreadCurrentGrantSelection

    init(grantKey: String) {
        context = JobTreadGrantContext(grantKey: grantKey)
        currentGrant = JobTreadCurrentGrantSelection()
    }

    enum CodingKeys: String, CodingKey {
        case context = "$"
        case currentGrant
    }
}

private struct JobTreadGrantContext: Encodable {
    let grantKey: String
}

private struct JobTreadCurrentGrantSelection: Encodable {
    let id = JobTreadEmptySelection()
    let user = JobTreadUserSelection()
}

private struct JobTreadUserSelection: Encodable {
    let id = JobTreadEmptySelection()
    let name = JobTreadEmptySelection()
    let memberships = JobTreadMembershipsSelection()
}

private struct JobTreadMembershipsSelection: Encodable {
    let nodes = JobTreadMembershipSelection()
}

private struct JobTreadMembershipSelection: Encodable {
    let organization = JobTreadOrganizationSelection()
}

private struct JobTreadOrganizationSelection: Encodable {
    let id = JobTreadEmptySelection()
    let name = JobTreadEmptySelection()
}

private struct JobTreadEmptySelection: Encodable {}

private struct JobTreadCurrentGrantEnvelope: Decodable {
    let currentGrant: JobTreadCurrentGrant?
    let errors: [JobTreadAPIError]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let dataContainer = try? container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data) {
            currentGrant = try dataContainer.decodeIfPresent(JobTreadCurrentGrant.self, forKey: .currentGrant)
        } else {
            currentGrant = try container.decodeIfPresent(JobTreadCurrentGrant.self, forKey: .currentGrant)
        }

        errors = try container.decodeIfPresent([JobTreadAPIError].self, forKey: .errors) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case data
        case currentGrant
        case errors
    }

    private enum DataCodingKeys: String, CodingKey {
        case currentGrant
    }
}

private struct JobTreadAPIError: Decodable {
    let message: String
}
