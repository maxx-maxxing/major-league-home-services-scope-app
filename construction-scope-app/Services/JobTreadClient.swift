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

protocol JobTreadCustomerSearching {
    func searchCustomers(matching query: String, limit: Int) async throws -> [JobTreadCustomerLookupResult]
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
        let envelope: JobTreadCurrentGrantEnvelope = try await send(requestBody)

        if !envelope.errors.isEmpty {
            throw JobTreadClientError.apiErrors(envelope.errors.map(\.message))
        }

        guard let currentGrant = envelope.currentGrant else {
            throw JobTreadClientError.emptyCurrentGrant
        }

        return currentGrant
    }
}

extension JobTreadClient: JobTreadCustomerSearching {
    func searchCustomers(matching query: String, limit: Int = 20) async throws -> [JobTreadCustomerLookupResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        let requestBody = JobTreadCustomerSearchRequest(
            grantKey: config.apiKey,
            organizationID: config.organizationID,
            searchText: trimmedQuery,
            limit: limit
        )
        logCustomerSearchRequest(requestBody)
        let envelope: JobTreadCustomerSearchEnvelope = try await send(requestBody)

        if !envelope.errors.isEmpty {
            throw JobTreadClientError.apiErrors(envelope.errors.map(\.message))
        }

        let results = envelope.organization?.accounts?.nodes.map(\.lookupResult) ?? []
        print("[JobTread] customer search results: \(results.count) for query '\(trimmedQuery)'")
        return results
    }
}

private extension JobTreadClient {
    func send<RequestBody: Encodable, ResponseBody: Decodable>(_ requestBody: RequestBody) async throws -> ResponseBody {
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

        return try decoder.decode(ResponseBody.self, from: data)
    }

    func logCustomerSearchRequest(_ requestBody: JobTreadCustomerSearchRequest) {
        guard let data = try? encoder.encode(requestBody),
              let json = String(data: data, encoding: .utf8) else {
            print("[JobTread] customer search request: <encoding failed>")
            return
        }

        print("[JobTread] customer search request: \(json)")
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

private struct JobTreadCustomerSearchRequest: Encodable {
    let query: JobTreadCustomerSearchQuery

    init(grantKey: String, organizationID: String, searchText: String, limit: Int) {
        query = JobTreadCustomerSearchQuery(
            grantKey: grantKey,
            organizationID: organizationID,
            searchText: searchText,
            limit: limit
        )
    }
}

private struct JobTreadCustomerSearchQuery: Encodable {
    let context: JobTreadCustomerSearchContext
    let organization: JobTreadCustomerSearchOrganizationSelection

    init(grantKey: String, organizationID: String, searchText: String, limit: Int) {
        context = JobTreadCustomerSearchContext(grantKey: grantKey)
        organization = JobTreadCustomerSearchOrganizationSelection(
            organizationID: organizationID,
            searchText: searchText,
            limit: limit
        )
    }

    enum CodingKeys: String, CodingKey {
        case context = "$"
        case organization
    }
}

private struct JobTreadCustomerSearchContext: Encodable {
    let grantKey: String
}

private struct JobTreadCurrentGrantSelection: Encodable {
    let id = JobTreadEmptySelection()
    let user = JobTreadUserSelection()
}

private struct JobTreadCustomerSearchOrganizationSelection: Encodable {
    let options: JobTreadOrganizationSelectionOptions
    let accounts: JobTreadAccountsSelection

    init(organizationID: String, searchText: String, limit: Int) {
        options = JobTreadOrganizationSelectionOptions(id: organizationID)
        accounts = JobTreadAccountsSelection(searchText: searchText, limit: limit)
    }

    enum CodingKeys: String, CodingKey {
        case options = "$"
        case accounts
    }
}

private struct JobTreadOrganizationSelectionOptions: Encodable {
    let id: String
}

private struct JobTreadAccountsSelection: Encodable {
    let options: JobTreadCustomerSearchOptions
    let nodes = JobTreadAccountSelection()

    init(searchText: String, limit: Int) {
        options = JobTreadCustomerSearchOptions(searchText: searchText, limit: limit)
    }

    enum CodingKeys: String, CodingKey {
        case options = "$"
        case nodes
    }
}

private struct JobTreadCustomerSearchOptions: Encodable {
    let whereClause: JobTreadAccountWhereClause
    let size: Int

    init(searchText: String, limit: Int) {
        whereClause = JobTreadAccountWhereClause(searchText: searchText)
        size = limit
    }

    enum CodingKeys: String, CodingKey {
        case whereClause = "where"
        case size
    }
}

private struct JobTreadAccountWhereClause: Encodable {
    let and: [JobTreadAccountWhereCondition]

    init(searchText: String) {
        and = [
            JobTreadAccountWhereCondition(field: "name", comparison: "=", value: searchText),
            JobTreadAccountWhereCondition(field: "type", comparison: "=", value: "customer")
        ]
    }
}

private struct JobTreadAccountWhereCondition: Encodable {
    let field: String
    let comparison: String
    let value: String

    init(field: String, comparison: String, value: String) {
        self.field = field
        self.comparison = comparison
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(field)
        try container.encode(comparison)
        try container.encode(value)
    }
}

private struct JobTreadAccountSelection: Encodable {
    let id = JobTreadEmptySelection()
    let name = JobTreadEmptySelection()
    let type = JobTreadEmptySelection()
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

private struct JobTreadCustomerSearchEnvelope: Decodable {
    let organization: JobTreadCustomerSearchOrganizationNode?
    let errors: [JobTreadAPIError]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let dataContainer = try? container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data) {
            organization = try dataContainer.decodeIfPresent(JobTreadCustomerSearchOrganizationNode.self, forKey: .organization)
        } else {
            organization = try container.decodeIfPresent(JobTreadCustomerSearchOrganizationNode.self, forKey: .organization)
        }

        errors = try container.decodeIfPresent([JobTreadAPIError].self, forKey: .errors) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case data
        case organization
        case errors
    }

    private enum DataCodingKeys: String, CodingKey {
        case organization
    }
}

private struct JobTreadCustomerSearchOrganizationNode: Decodable {
    let accounts: JobTreadAccountConnection?
}

private struct JobTreadAccountConnection: Decodable {
    let nodes: [JobTreadAccountNode]
}

private struct JobTreadAccountNode: Decodable {
    let id: String
    let name: String?
    let type: String?

    var lookupResult: JobTreadCustomerLookupResult {
        JobTreadCustomerLookupResult(
            customerID: id,
            displayName: name,
            accountType: type,
            primaryAddress: nil,
            phone: nil,
            email: nil
        )
    }
}

private struct JobTreadAPIError: Decodable {
    let message: String
}
