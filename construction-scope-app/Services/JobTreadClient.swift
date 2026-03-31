import Foundation

enum JobTreadClientError: LocalizedError {
    case configurationUnavailable(JobTreadConfigError)
    case invalidResponse
    case unexpectedStatusCode(Int, body: String)
    case apiErrors([String])
    case emptyCurrentGrant

    var errorDescription: String? {
        switch self {
        case let .configurationUnavailable(error):
            return error.errorDescription
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

protocol JobTreadCustomerDetailFetching {
    func fetchCustomerDetails(customerID: String) async throws -> JobTreadCustomerDetail?
}

struct JobTreadCustomerDetail: Sendable {
    let customerID: String
    let displayName: String?
    let accountType: String?
    let primaryAddress: String?
    let unitNumber: String?
    let city: String?
    let state: String?
    let postalCode: String?
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
    private static let requestTimeout: TimeInterval = 8

    private let session: URLSession
    private let configResult: Result<JobTreadConfig, JobTreadConfigError>
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        configResult: Result<JobTreadConfig, JobTreadConfigError> = JobTreadConfig.load(),
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.configResult = configResult
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }

    func fetchCurrentGrant() async throws -> JobTreadCurrentGrant {
        let config = try resolvedConfig()
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
        _ = try resolvedConfig()
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        print("[JobTread] customer search start query='\(trimmedQuery)' mode=like-then-exact limit=\(limit)")

        let partialAttempts: [JobTreadPartialSearchAttempt] = [
            .prefixLike(trimmedQuery),
            .containsLike(trimmedQuery)
        ]

        for attempt in partialAttempts {
            do {
                let partialResults = try await performCustomerSearch(
                    matching: attempt.value,
                    limit: limit,
                    nameComparison: attempt.comparison
                )

                print("[JobTread] partial attempt complete operator=\(attempt.label) query='\(attempt.value)' results=\(partialResults.count)")

                if !partialResults.isEmpty {
                    print("[JobTread] customer search complete query='\(trimmedQuery)' mode=\(attempt.label) results=\(partialResults.count)")
                    return partialResults
                }
            } catch {
                print("[JobTread] partial attempt failed operator=\(attempt.label) query='\(attempt.value)' error='\(error.localizedDescription)'")
            }
        }

        print("[JobTread] customer search fallback query='\(trimmedQuery)' reason=no successful partial-like match")
        let exactResults = try await performCustomerSearch(
            matching: trimmedQuery,
            limit: limit,
            nameComparison: .equalTo
        )
        print("[JobTread] customer search complete query='\(trimmedQuery)' mode=exact-fallback results=\(exactResults.count)")
        return exactResults
    }
}

extension JobTreadClient: JobTreadCustomerDetailFetching {
    func fetchCustomerDetails(customerID: String) async throws -> JobTreadCustomerDetail? {
        let config = try resolvedConfig()
        let trimmedCustomerID = customerID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCustomerID.isEmpty else { return nil }

        let requestBody = JobTreadCustomerDetailRequest(
            grantKey: config.apiKey,
            organizationID: config.organizationID,
            customerID: trimmedCustomerID
        )
        logCustomerDetailRequest(requestBody)

        do {
            let envelope: JobTreadCustomerDetailEnvelope = try await send(requestBody)

            if !envelope.errors.isEmpty {
                let messages = envelope.errors.map(\.message)
                print("[JobTread] customer detail api errors customerID='\(trimmedCustomerID)': \(messages.joined(separator: " | "))")
                throw JobTreadClientError.apiErrors(messages)
            }

            let detail = envelope.organization?.accounts?.nodes.first?.customerDetail
            let status = detail == nil ? "missing" : "found"
            print("[JobTread] customer detail response customerID='\(trimmedCustomerID)' status=\(status)")
            return detail
        } catch {
            print("[JobTread] customer detail failed customerID='\(trimmedCustomerID)': \(error.localizedDescription)")
            throw error
        }
    }
}

private extension JobTreadClient {
    func resolvedConfig() throws -> JobTreadConfig {
        switch configResult {
        case let .success(config):
            return config
        case let .failure(error):
            throw JobTreadClientError.configurationUnavailable(error)
        }
    }

    func performCustomerSearch(
        matching query: String,
        limit: Int,
        nameComparison: JobTreadNameComparison
    ) async throws -> [JobTreadCustomerLookupResult] {
        let config = try resolvedConfig()
        let requestBody = JobTreadCustomerSearchRequest(
            grantKey: config.apiKey,
            organizationID: config.organizationID,
            searchText: query,
            limit: limit,
            nameComparison: nameComparison
        )
        logCustomerSearchRequest(requestBody, nameComparison: nameComparison)
        do {
            let envelope: JobTreadCustomerSearchEnvelope = try await send(requestBody)

            if !envelope.errors.isEmpty {
                let messages = envelope.errors.map(\.message)
                print("[JobTread] customer search api errors mode=\(nameComparison.rawValue) query='\(query)': \(messages.joined(separator: " | "))")
                throw JobTreadClientError.apiErrors(messages)
            }

            let results = envelope.organization?.accounts?.nodes.map(\.lookupResult) ?? []
            print("[JobTread] customer search response mode=\(nameComparison.rawValue) query='\(query)' results=\(results.count)")
            return results
        } catch {
            print("[JobTread] customer search failed mode=\(nameComparison.rawValue) query='\(query)': \(error.localizedDescription)")
            throw error
        }
    }

    func send<RequestBody: Encodable, ResponseBody: Decodable>(_ requestBody: RequestBody) async throws -> ResponseBody {
        let config = try resolvedConfig()
        var request = URLRequest(url: config.baseURL)
        request.httpMethod = "POST"
        request.timeoutInterval = Self.requestTimeout
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

    func logCustomerSearchRequest(
        _ requestBody: JobTreadCustomerSearchRequest,
        nameComparison: JobTreadNameComparison
    ) {
        guard let data = try? encoder.encode(requestBody),
              let json = String(data: data, encoding: .utf8) else {
            print("[JobTread] customer search request: <encoding failed>")
            return
        }

        print("[JobTread] customer search request (\(nameComparison.rawValue)): \(json)")
    }

    func logCustomerDetailRequest(_ requestBody: JobTreadCustomerDetailRequest) {
        guard let data = try? encoder.encode(requestBody),
              let json = String(data: data, encoding: .utf8) else {
            print("[JobTread] customer detail request: <encoding failed>")
            return
        }

        print("[JobTread] customer detail request: \(json)")
    }
}

private struct JobTreadPartialSearchAttempt {
    let comparison: JobTreadNameComparison
    let value: String
    let label: String

    static func prefixLike(_ query: String) -> Self {
        Self(comparison: .like, value: "\(query)%", label: "like-prefix")
    }

    static func containsLike(_ query: String) -> Self {
        Self(comparison: .like, value: "%\(query)%", label: "like-contains")
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

    init(
        grantKey: String,
        organizationID: String,
        searchText: String,
        limit: Int,
        nameComparison: JobTreadNameComparison
    ) {
        query = JobTreadCustomerSearchQuery(
            grantKey: grantKey,
            organizationID: organizationID,
            searchText: searchText,
            limit: limit,
            nameComparison: nameComparison
        )
    }
}

private struct JobTreadCustomerDetailRequest: Encodable {
    let query: JobTreadCustomerDetailQuery

    init(grantKey: String, organizationID: String, customerID: String) {
        query = JobTreadCustomerDetailQuery(
            grantKey: grantKey,
            organizationID: organizationID,
            customerID: customerID
        )
    }
}

private struct JobTreadCustomerSearchQuery: Encodable {
    let context: JobTreadCustomerSearchContext
    let organization: JobTreadCustomerSearchOrganizationSelection

    init(
        grantKey: String,
        organizationID: String,
        searchText: String,
        limit: Int,
        nameComparison: JobTreadNameComparison
    ) {
        context = JobTreadCustomerSearchContext(grantKey: grantKey)
        organization = JobTreadCustomerSearchOrganizationSelection(
            organizationID: organizationID,
            searchText: searchText,
            limit: limit,
            nameComparison: nameComparison
        )
    }

    enum CodingKeys: String, CodingKey {
        case context = "$"
        case organization
    }
}

private struct JobTreadCustomerDetailQuery: Encodable {
    let context: JobTreadCustomerSearchContext
    let organization: JobTreadCustomerDetailOrganizationSelection

    init(grantKey: String, organizationID: String, customerID: String) {
        context = JobTreadCustomerSearchContext(grantKey: grantKey)
        organization = JobTreadCustomerDetailOrganizationSelection(
            organizationID: organizationID,
            customerID: customerID
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

    init(
        organizationID: String,
        searchText: String,
        limit: Int,
        nameComparison: JobTreadNameComparison
    ) {
        options = JobTreadOrganizationSelectionOptions(id: organizationID)
        accounts = JobTreadAccountsSelection(
            searchText: searchText,
            limit: limit,
            nameComparison: nameComparison
        )
    }

    enum CodingKeys: String, CodingKey {
        case options = "$"
        case accounts
    }
}

private struct JobTreadCustomerDetailOrganizationSelection: Encodable {
    let options: JobTreadOrganizationSelectionOptions
    let accounts: JobTreadCustomerDetailAccountsSelection

    init(organizationID: String, customerID: String) {
        options = JobTreadOrganizationSelectionOptions(id: organizationID)
        accounts = JobTreadCustomerDetailAccountsSelection(customerID: customerID)
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

    init(searchText: String, limit: Int, nameComparison: JobTreadNameComparison) {
        options = JobTreadCustomerSearchOptions(
            searchText: searchText,
            limit: limit,
            nameComparison: nameComparison
        )
    }

    enum CodingKeys: String, CodingKey {
        case options = "$"
        case nodes
    }
}

private struct JobTreadCustomerDetailAccountsSelection: Encodable {
    let options: JobTreadCustomerDetailOptions
    let nodes = JobTreadCustomerDetailAccountSelection()

    init(customerID: String) {
        options = JobTreadCustomerDetailOptions(customerID: customerID)
    }

    enum CodingKeys: String, CodingKey {
        case options = "$"
        case nodes
    }
}

private struct JobTreadCustomerSearchOptions: Encodable {
    let whereClause: JobTreadAccountWhereClause
    let size: Int

    init(searchText: String, limit: Int, nameComparison: JobTreadNameComparison) {
        whereClause = JobTreadAccountWhereClause(
            searchText: searchText,
            nameComparison: nameComparison
        )
        size = limit
    }

    enum CodingKeys: String, CodingKey {
        case whereClause = "where"
        case size
    }
}

private struct JobTreadCustomerDetailOptions: Encodable {
    let whereClause: JobTreadCustomerDetailWhereClause
    let size = 1

    init(customerID: String) {
        whereClause = JobTreadCustomerDetailWhereClause(customerID: customerID)
    }

    enum CodingKeys: String, CodingKey {
        case whereClause = "where"
        case size
    }
}

private struct JobTreadAccountWhereClause: Encodable {
    let and: [JobTreadAccountWhereCondition]

    init(searchText: String, nameComparison: JobTreadNameComparison) {
        and = [
            JobTreadAccountWhereCondition(
                field: "name",
                comparison: nameComparison.rawValue,
                value: searchText
            ),
            JobTreadAccountWhereCondition(field: "type", comparison: "=", value: "customer")
        ]
    }
}

private struct JobTreadCustomerDetailWhereClause: Encodable {
    let and: [JobTreadAccountWhereCondition]

    init(customerID: String) {
        and = [
            JobTreadAccountWhereCondition(field: "id", comparison: "=", value: customerID),
            JobTreadAccountWhereCondition(field: "type", comparison: "=", value: "customer")
        ]
    }
}

private enum JobTreadNameComparison: String {
    case contains
    case like
    case equalTo = "="
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

private struct JobTreadCustomerDetailAccountSelection: Encodable {
    let id = JobTreadEmptySelection()
    let name = JobTreadEmptySelection()
    let type = JobTreadEmptySelection()
    let primaryLocation = JobTreadLocationSelection()
    let locations = JobTreadLocationsSelection()
}

private struct JobTreadLocationsSelection: Encodable {
    let options = JobTreadSingleNodeOptions()
    let nodes = JobTreadLocationSelection()

    enum CodingKeys: String, CodingKey {
        case options = "$"
        case nodes
    }
}

private struct JobTreadSingleNodeOptions: Encodable {
    let size = 1
}

private struct JobTreadLocationSelection: Encodable {
    let id = JobTreadEmptySelection()
    let name = JobTreadEmptySelection()
    let address = JobTreadEmptySelection()
    let city = JobTreadEmptySelection()
    let state = JobTreadEmptySelection()
    let postalCode = JobTreadEmptySelection()
    let formattedAddress = JobTreadEmptySelection()
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

private struct JobTreadCustomerDetailEnvelope: Decodable {
    let organization: JobTreadCustomerDetailOrganizationNode?
    let errors: [JobTreadAPIError]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let dataContainer = try? container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data) {
            organization = try dataContainer.decodeIfPresent(JobTreadCustomerDetailOrganizationNode.self, forKey: .organization)
        } else {
            organization = try container.decodeIfPresent(JobTreadCustomerDetailOrganizationNode.self, forKey: .organization)
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

private struct JobTreadCustomerDetailOrganizationNode: Decodable {
    let accounts: JobTreadCustomerDetailAccountConnection?
}

private struct JobTreadCustomerDetailAccountConnection: Decodable {
    let nodes: [JobTreadCustomerDetailNode]
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

private struct JobTreadCustomerDetailNode: Decodable {
    let id: String
    let name: String?
    let type: String?
    let primaryLocation: JobTreadLocationNode?
    let locations: JobTreadLocationConnectionNode?

    var customerDetail: JobTreadCustomerDetail {
        let resolvedLocation = primaryLocation ?? locations?.nodes.first

        return JobTreadCustomerDetail(
            customerID: id,
            displayName: name,
            accountType: type,
            primaryAddress: resolvedLocation?.resolvedAddressParts.streetAddress,
            unitNumber: resolvedLocation?.resolvedAddressParts.unitNumber,
            city: resolvedLocation?.city,
            state: resolvedLocation?.state,
            postalCode: resolvedLocation?.postalCode
        )
    }
}

private struct JobTreadLocationConnectionNode: Decodable {
    let nodes: [JobTreadLocationNode]
}

private struct JobTreadLocationNode: Decodable {
    let id: String?
    let name: String?
    let address: String?
    let city: String?
    let state: String?
    let postalCode: String?
    let formattedAddress: String?

    var resolvedAddressParts: ResolvedAddressParts {
        let resolvedStreetAddress = resolvedStreetAddressParts

        if resolvedStreetAddress.unitNumber != nil {
            return resolvedStreetAddress
        }

        if let displayNameUnitNumber = extractTrailingUnitNumber(from: name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty)?.unitNumber {
            return ResolvedAddressParts(
                streetAddress: resolvedStreetAddress.streetAddress,
                unitNumber: displayNameUnitNumber
            )
        }

        return resolvedStreetAddress
    }

    private var resolvedStreetAddressParts: ResolvedAddressParts {
        let resolvedFromAddress = sanitizedAddressParts(from: address)
        if resolvedFromAddress.streetAddress != nil || resolvedFromAddress.unitNumber != nil {
            return resolvedFromAddress
        }

        return sanitizedAddressParts(from: formattedAddress)
    }

    private func sanitizedAddressParts(from rawValue: String?) -> ResolvedAddressParts {
        guard let trimmedValue = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty else {
            return .empty
        }

        let components = trimmedValue
            .split(separator: ",", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let firstComponent = components.first?.nilIfEmpty else {
            return .empty
        }

        var sanitizedFirstComponent = trimmingTrailingCitySuffixIfNeeded(from: firstComponent)
        var resolvedUnitNumber: String?

        if let parsedInlineUnit = extractTrailingUnitNumber(from: sanitizedFirstComponent) {
            sanitizedFirstComponent = parsedInlineUnit.streetAddress
            resolvedUnitNumber = parsedInlineUnit.unitNumber
        }

        if components.count == 1 {
            guard let sanitizedFirstComponent else { return .empty }
            return valueContainsKnownLocationParts(sanitizedFirstComponent)
                ? .empty
                : ResolvedAddressParts(streetAddress: sanitizedFirstComponent, unitNumber: resolvedUnitNumber)
        }

        var remainingComponents = Array(components.dropFirst())

        if resolvedUnitNumber == nil,
           let lastComponent = remainingComponents.last,
           let trailingLocationUnit = extractTrailingUnitNumberFromLocationComponent(lastComponent) {
            remainingComponents[remainingComponents.count - 1] = trailingLocationUnit.locationComponent
            resolvedUnitNumber = trailingLocationUnit.unitNumber
        }

        if let explicitUnitComponent = remainingComponents.first?.nilIfEmpty,
           isClearlyUnitNumberComponent(explicitUnitComponent) {
            let trailingLocationComponents = remainingComponents.dropFirst()
            let canAcceptTrailingLocationComponents = trailingLocationComponents.isEmpty || formattedAddressContainsOnlyKnownLocationParts(trailingLocationComponents)

            if canAcceptTrailingLocationComponents, let sanitizedFirstComponent {
                return valueContainsKnownLocationParts(sanitizedFirstComponent)
                    ? .empty
                    : ResolvedAddressParts(streetAddress: sanitizedFirstComponent, unitNumber: explicitUnitComponent)
            }
        }

        // Only recover a street line when the remaining segments clearly match
        // dedicated location fields that hydrate separately.
        if formattedAddressContainsOnlyKnownLocationParts(remainingComponents), let sanitizedFirstComponent {
            return ResolvedAddressParts(streetAddress: sanitizedFirstComponent, unitNumber: resolvedUnitNumber)
        }

        return .empty
    }

    private func formattedAddressContainsOnlyKnownLocationParts<S: Sequence>(_ components: S) -> Bool where S.Element == String {
        let normalizedExpected = Set(
            [city, state, postalCode, "USA", "United States"]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty?.lowercased() }
        )

        guard !normalizedExpected.isEmpty else { return false }

        for component in components {
            let normalizedComponent = component.lowercased()

            if normalizedExpected.contains(normalizedComponent) {
                continue
            }

            let tokens = normalizedComponent
                .split(whereSeparator: { $0 == " " || $0 == "-" })
                .map(String.init)
                .filter { !$0.isEmpty }

            if tokens.allSatisfy({ normalizedExpected.contains($0) }) {
                continue
            }

            return false
        }

        return true
    }

    private func valueContainsKnownLocationParts(_ value: String) -> Bool {
        let normalizedValue = value.lowercased()

        if let city = city?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty?.lowercased(),
           normalizedValue.contains(city) {
            return true
        }

        if let state = state?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty?.lowercased(),
           normalizedValue.contains(state) {
            return true
        }

        if let postalCode = postalCode?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty?.lowercased(),
           normalizedValue.contains(postalCode) {
            return true
        }

        return normalizedValue.contains("usa") || normalizedValue.contains("united states")
    }

    private func trimmingTrailingCitySuffixIfNeeded(from value: String) -> String? {
        guard let city = city?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty else {
            return value
        }

        let normalizedValue = value.lowercased()
        let normalizedCity = city.lowercased()

        guard normalizedValue.count > normalizedCity.count else {
            return value
        }

        guard normalizedValue.hasSuffix(normalizedCity) else {
            return value
        }

        let suffixStartIndex = normalizedValue.index(normalizedValue.endIndex, offsetBy: -normalizedCity.count)
        guard suffixStartIndex > normalizedValue.startIndex else {
            return value
        }

        let boundaryIndex = normalizedValue.index(before: suffixStartIndex)
        guard normalizedValue[boundaryIndex].isWhitespace else {
            return value
        }

        let trimmedStreet = value[..<boundaryIndex]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty

        return trimmedStreet
    }

    private func extractTrailingUnitNumber(from value: String?) -> ResolvedAddressParts? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty else {
            return nil
        }

        guard value.rangeOfCharacter(from: .decimalDigits) != nil else {
            return nil
        }

        let pattern = #"(?i)^(.*?)(?:\s+|,\s*)(#\s*[A-Za-z0-9-]+|(?:apt\.?|apartment|unit|ste\.?|suite|lot|bldg\.?|building|fl\.?|floor|rm\.?|room)\s*[A-Za-z0-9-]+(?:\s+[A-Za-z0-9-]+)?)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        guard let match = regex.firstMatch(in: value, options: [], range: range),
              match.numberOfRanges == 3,
              let streetRange = Range(match.range(at: 1), in: value),
              let unitRange = Range(match.range(at: 2), in: value) else {
            return nil
        }

        let streetAddress = value[streetRange].trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let unitNumber = value[unitRange].trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        guard let streetAddress, let unitNumber else { return nil }
        return ResolvedAddressParts(streetAddress: streetAddress, unitNumber: unitNumber)
    }

    private func extractTrailingUnitNumberFromLocationComponent(_ value: String) -> (locationComponent: String, unitNumber: String)? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return nil }

        // Only strip a trailing unit from a location component when the leading
        // portion still looks like city/state/ZIP data that hydrates separately.
        let pattern = #"(?i)^(.*?\b\d{5}(?:-\d{4})?)(?:\s+)(unit\s+[A-Za-z0-9-]+(?:\s+[A-Za-z0-9-]+)*)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(trimmedValue.startIndex..<trimmedValue.endIndex, in: trimmedValue)
        guard let match = regex.firstMatch(in: trimmedValue, options: [], range: range),
              match.numberOfRanges == 3,
              let locationRange = Range(match.range(at: 1), in: trimmedValue),
              let unitRange = Range(match.range(at: 2), in: trimmedValue) else {
            return nil
        }

        let locationComponent = trimmedValue[locationRange].trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let unitNumber = trimmedValue[unitRange].trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        guard let locationComponent, let unitNumber else { return nil }
        return (locationComponent, unitNumber)
    }

    private func isClearlyUnitNumberComponent(_ value: String) -> Bool {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return false }

        let pattern = #"(?i)^(#\s*[A-Za-z0-9-]+|(?:apt\.?|apartment|unit|ste\.?|suite|lot|bldg\.?|building|fl\.?|floor|rm\.?|room)\s*[A-Za-z0-9-]+(?:\s+[A-Za-z0-9-]+)?)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }

        let range = NSRange(trimmedValue.startIndex..<trimmedValue.endIndex, in: trimmedValue)
        return regex.firstMatch(in: trimmedValue, options: [], range: range) != nil
    }
}

private struct ResolvedAddressParts {
    let streetAddress: String?
    let unitNumber: String?

    static let empty = ResolvedAddressParts(streetAddress: nil, unitNumber: nil)
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private struct JobTreadAPIError: Decodable {
    let message: String
}
