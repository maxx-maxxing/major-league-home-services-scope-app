import Foundation

private struct ContractTestFailure: Error, CustomStringConvertible {
    let description: String
}

private final class OfflineURLProtocol: URLProtocol {
    struct Stub {
        let statusCode: Int
        let responseBody: Data
        let validate: (URLRequest) throws -> Void
    }

    private static let lock = NSLock()
    private static var stubs: [Stub] = []
    private static var completedRequestCount = 0
    private static var recordedFailure: ContractTestFailure?

    static func install(_ newStubs: [Stub]) {
        lock.lock()
        stubs = newStubs
        completedRequestCount = 0
        recordedFailure = nil
        lock.unlock()
    }

    static func verifyComplete(expectedRequestCount: Int) throws {
        lock.lock()
        let remainingCount = stubs.count
        let actualRequestCount = completedRequestCount
        let failure = recordedFailure
        lock.unlock()

        if let failure {
            throw failure
        }
        guard remainingCount == 0 else {
            throw ContractTestFailure(description: "mock transport did not receive every expected request")
        }
        guard actualRequestCount == expectedRequestCount else {
            throw ContractTestFailure(description: "mock transport received an unexpected number of requests")
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        do {
            let stub = try Self.takeNextStub()
            try stub.validate(request)

            guard let url = request.url,
                  let response = HTTPURLResponse(
                    url: url,
                    statusCode: stub.statusCode,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "application/json"]
                  ) else {
                throw ContractTestFailure(description: "mock transport could not construct a local response")
            }

            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: stub.responseBody)
            client?.urlProtocolDidFinishLoading(self)
        } catch let failure as ContractTestFailure {
            Self.record(failure)
            client?.urlProtocol(self, didFailWithError: failure)
        } catch {
            let failure = ContractTestFailure(description: "mock transport failed with an unexpected error type")
            Self.record(failure)
            client?.urlProtocol(self, didFailWithError: failure)
        }
    }

    override func stopLoading() {}

    private static func takeNextStub() throws -> Stub {
        lock.lock()
        defer { lock.unlock() }

        guard !stubs.isEmpty else {
            throw ContractTestFailure(description: "mock transport blocked an unexpected request")
        }

        completedRequestCount += 1
        return stubs.removeFirst()
    }

    private static func record(_ failure: ContractTestFailure) {
        lock.lock()
        if recordedFailure == nil {
            recordedFailure = failure
        }
        lock.unlock()
    }
}

@main
private enum JobTreadReadContractTests {
    private static let fixtureGrant = "fixture-grant"
    private static let fixtureOrganizationID = "fixture-organization"
    private static let fixtureCustomerID = "fixture-customer-1"
    private static let fixtureBaseURL = URL(string: "https://jobtread-contract.invalid/pave")!

    static func main() async {
        do {
            try await testWhitespaceSearchDoesNotUseTransport()
            try await testPrefixSearchReturnsImmediately()
            try await testContainsSearchReturnsAfterEmptyPrefix()
            try await testSearchFallbackRequestAndResponseContract()
            try await testCustomerDetailRequestAndMappingContract()
            try await testPrimaryContactFallbackMappingContract()
            try await testCustomerDetailFallbackMappingContract()
            try await testCustomerDetailAPIErrorsAreCountOnly()
            try await testUnexpectedHTTPStatusIsClassified()
            print("JobTread read contract tests passed")
        } catch let failure as ContractTestFailure {
            fail(failure.description)
        } catch {
            fail("unexpected test failure type: \(String(describing: type(of: error)))")
        }
    }

    private static func testWhitespaceSearchDoesNotUseTransport() async throws {
        OfflineURLProtocol.install([])
        let results = try await makeClient().searchCustomers(matching: "  \n\t ", limit: 7)

        try require(results.isEmpty, "whitespace-only search returned results")
        try OfflineURLProtocol.verifyComplete(expectedRequestCount: 0)
    }

    private static func testPrefixSearchReturnsImmediately() async throws {
        OfflineURLProtocol.install([
            searchStub(
                searchValue: "Fixture%",
                comparison: "like",
                statusCode: 200,
                responseBody: fixtureData(searchResultResponse)
            )
        ])

        let results = try await makeClient().searchCustomers(matching: "Fixture", limit: 7)
        try OfflineURLProtocol.verifyComplete(expectedRequestCount: 1)
        try requireFixtureSearchResult(results)
    }

    private static func testContainsSearchReturnsAfterEmptyPrefix() async throws {
        OfflineURLProtocol.install([
            searchStub(
                searchValue: "Fixture%",
                comparison: "like",
                statusCode: 200,
                responseBody: fixtureData(emptySearchResponse)
            ),
            searchStub(
                searchValue: "%Fixture%",
                comparison: "like",
                statusCode: 200,
                responseBody: fixtureData(searchResultResponse)
            )
        ])

        let results = try await makeClient().searchCustomers(matching: "Fixture", limit: 7)
        try OfflineURLProtocol.verifyComplete(expectedRequestCount: 2)
        try requireFixtureSearchResult(results)
    }

    private static func testSearchFallbackRequestAndResponseContract() async throws {
        OfflineURLProtocol.install([
            searchStub(
                searchValue: "Fixture%",
                comparison: "like",
                statusCode: 200,
                responseBody: fixtureData(emptySearchResponse)
            ),
            searchStub(
                searchValue: "%Fixture%",
                comparison: "like",
                statusCode: 200,
                responseBody: fixtureData(
                    #"{"errors":[{"message":"synthetic partial-search rejection"}]}"#
                )
            ),
            searchStub(
                searchValue: "Fixture",
                comparison: "=",
                statusCode: 200,
                responseBody: fixtureData(searchResultResponse)
            )
        ])

        let results: [JobTreadCustomerLookupResult]
        do {
            results = try await makeClient().searchCustomers(matching: "  Fixture  ", limit: 7)
        } catch {
            try OfflineURLProtocol.verifyComplete(expectedRequestCount: 3)
            throw ContractTestFailure(description: "customer search unexpectedly failed")
        }

        try OfflineURLProtocol.verifyComplete(expectedRequestCount: 3)
        try requireFixtureSearchResult(results)
    }

    private static func requireFixtureSearchResult(_ results: [JobTreadCustomerLookupResult]) throws {
        try require(results.count == 1, "search returned the wrong fixture result count")
        guard let result = results.first else {
            throw ContractTestFailure(description: "search did not return its fixture customer")
        }
        try require(result.customerID == fixtureCustomerID, "search mapped the wrong customer identifier")
        try require(result.displayName == "Fixture Customer", "search mapped the wrong customer name")
        try require(result.accountType == "customer", "search mapped the wrong account type")
        try require(result.primaryAddress == nil, "search unexpectedly hydrated an address")
        try require(result.phone == nil, "search unexpectedly hydrated a phone number")
        try require(result.email == nil, "search unexpectedly hydrated an email address")
    }

    private static func testCustomerDetailRequestAndMappingContract() async throws {
        OfflineURLProtocol.install([
            OfflineURLProtocol.Stub(
                statusCode: 200,
                responseBody: fixtureData(customerDetailResponse),
                validate: { request in
                    let query = try validateCommonRequest(request)
                    try validateDetailQuery(query, customerID: fixtureCustomerID)
                }
            )
        ])

        let detail: JobTreadCustomerDetail?
        do {
            detail = try await makeClient().fetchCustomerDetails(customerID: "  \(fixtureCustomerID)  ")
        } catch {
            try OfflineURLProtocol.verifyComplete(expectedRequestCount: 1)
            throw ContractTestFailure(description: "customer detail lookup unexpectedly failed")
        }

        try OfflineURLProtocol.verifyComplete(expectedRequestCount: 1)
        guard let detail else {
            throw ContractTestFailure(description: "customer detail fixture decoded as missing")
        }

        try require(detail.customerID == fixtureCustomerID, "detail mapped the wrong customer identifier")
        try require(detail.displayName == "Fixture Customer", "detail mapped the wrong customer name")
        try require(detail.accountType == "customer", "detail mapped the wrong account type")
        try require(detail.primaryAddress == "11000 Example Rd", "detail mapped the wrong street address")
        try require(detail.unitNumber == "Unit 64", "detail mapped the wrong unit number")
        try require(detail.city == "Austin", "detail mapped the wrong city")
        try require(detail.state == "TX", "detail mapped the wrong state")
        try require(detail.postalCode == "78750", "detail mapped the wrong postal code")
        try require(detail.phone == "512-555-0100", "account phone did not win contact-source priority")
        try require(detail.email == "account@example.invalid", "account email did not win contact-source priority")
    }

    private static func testPrimaryContactFallbackMappingContract() async throws {
        OfflineURLProtocol.install([
            OfflineURLProtocol.Stub(
                statusCode: 200,
                responseBody: fixtureData(customerDetailPrimaryContactFallbackResponse),
                validate: { request in
                    let query = try validateCommonRequest(request)
                    try validateDetailQuery(query, customerID: fixtureCustomerID)
                }
            )
        ])

        let detail: JobTreadCustomerDetail?
        do {
            detail = try await makeClient().fetchCustomerDetails(customerID: fixtureCustomerID)
        } catch {
            try OfflineURLProtocol.verifyComplete(expectedRequestCount: 1)
            throw ContractTestFailure(description: "primary-contact fallback lookup unexpectedly failed")
        }

        try OfflineURLProtocol.verifyComplete(expectedRequestCount: 1)
        guard let detail else {
            throw ContractTestFailure(description: "primary-contact fallback fixture decoded as missing")
        }

        try require(detail.phone == "720-555-0102", "primary contact did not supply the phone fallback")
        try require(detail.email == "primary-fallback@example.invalid", "primary contact did not supply the email fallback")
    }

    private static func testCustomerDetailFallbackMappingContract() async throws {
        OfflineURLProtocol.install([
            OfflineURLProtocol.Stub(
                statusCode: 200,
                responseBody: fixtureData(customerDetailFallbackResponse),
                validate: { request in
                    let query = try validateCommonRequest(request)
                    try validateDetailQuery(query, customerID: fixtureCustomerID)
                }
            )
        ])

        let detail: JobTreadCustomerDetail?
        do {
            detail = try await makeClient().fetchCustomerDetails(customerID: fixtureCustomerID)
        } catch {
            try OfflineURLProtocol.verifyComplete(expectedRequestCount: 1)
            throw ContractTestFailure(description: "customer detail fallback lookup unexpectedly failed")
        }

        try OfflineURLProtocol.verifyComplete(expectedRequestCount: 1)
        guard let detail else {
            throw ContractTestFailure(description: "customer detail fallback fixture decoded as missing")
        }

        try require(detail.primaryAddress == "22000 Fallback Rd", "fallback location did not supply the street address")
        try require(detail.unitNumber == "#5", "fallback location did not supply the unit number")
        try require(detail.city == "Boulder", "fallback location did not supply the city")
        try require(detail.state == "CO", "fallback location did not supply the state")
        try require(detail.postalCode == "80301", "fallback location did not supply the postal code")
        try require(detail.phone == "303-555-0101", "related contact did not supply the final phone fallback")
        try require(detail.email == "fallback@example.invalid", "related contact did not supply the final email fallback")
    }

    private static func testCustomerDetailAPIErrorsAreCountOnly() async throws {
        OfflineURLProtocol.install([
            OfflineURLProtocol.Stub(
                statusCode: 200,
                responseBody: fixtureData(
                    #"{"errors":[{"message":"synthetic private detail one"},{"message":"synthetic private detail two"}]}"#
                ),
                validate: { request in
                    let query = try validateCommonRequest(request)
                    try validateDetailQuery(query, customerID: fixtureCustomerID)
                }
            )
        ])

        do {
            _ = try await makeClient().fetchCustomerDetails(customerID: fixtureCustomerID)
            throw ContractTestFailure(description: "customer detail API errors were accepted as success")
        } catch let error as JobTreadClientError {
            guard case .apiErrors(2) = error else {
                throw ContractTestFailure(description: "customer detail API errors were classified incorrectly")
            }
            let message = error.errorDescription ?? ""
            try require(!message.contains("synthetic private detail"), "client error exposed an API message")
        }

        try OfflineURLProtocol.verifyComplete(expectedRequestCount: 1)
    }

    private static func testUnexpectedHTTPStatusIsClassified() async throws {
        OfflineURLProtocol.install([
            OfflineURLProtocol.Stub(
                statusCode: 503,
                responseBody: fixtureData(#"{"errors":[]}"#),
                validate: { request in
                    let query = try validateCommonRequest(request)
                    try validateDetailQuery(query, customerID: fixtureCustomerID)
                }
            )
        ])

        do {
            _ = try await makeClient().fetchCustomerDetails(customerID: fixtureCustomerID)
            throw ContractTestFailure(description: "non-success HTTP status was accepted")
        } catch let error as JobTreadClientError {
            guard case .unexpectedStatusCode(503) = error else {
                throw ContractTestFailure(description: "HTTP status was classified incorrectly")
            }
        }

        try OfflineURLProtocol.verifyComplete(expectedRequestCount: 1)
    }

    private static func makeClient() throws -> JobTreadClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [OfflineURLProtocol.self]
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData

        let config = try JobTreadConfig(values: [
            "JOBTREAD_API_KEY": fixtureGrant,
            "JOBTREAD_ORG_ID": fixtureOrganizationID,
            "JOBTREAD_API_BASE_URL": fixtureBaseURL.absoluteString
        ])

        return JobTreadClient(
            configResult: .success(config),
            session: URLSession(configuration: configuration)
        )
    }

    private static func searchStub(
        searchValue: String,
        comparison: String,
        statusCode: Int,
        responseBody: Data
    ) -> OfflineURLProtocol.Stub {
        OfflineURLProtocol.Stub(
            statusCode: statusCode,
            responseBody: responseBody,
            validate: { request in
                let query = try validateCommonRequest(request)
                try validateSearchQuery(
                    query,
                    searchValue: searchValue,
                    comparison: comparison,
                    limit: 7
                )
            }
        )
    }

    private static func validateCommonRequest(_ request: URLRequest) throws -> [String: Any] {
        try require(request.url == fixtureBaseURL, "request used an unexpected endpoint")
        try require(request.httpMethod == "POST", "request did not use POST")
        try require(request.timeoutInterval == 8, "request timeout changed")
        try require(request.value(forHTTPHeaderField: "Content-Type") == "application/json", "request content type changed")
        try require(request.value(forHTTPHeaderField: "Accept") == "application/json", "request accept header changed")

        let body = try requestBodyData(request)
        guard let root = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
            throw ContractTestFailure(description: "request body was not a JSON object")
        }

        try require(Set(root.keys) == ["query"], "request body contains an unexpected root field")
        let query = try dictionary(root["query"], label: "query")
        try require(Set(query.keys) == ["$", "organization"], "query selection changed unexpectedly")

        let context = try dictionary(query["$"], label: "query context")
        try require(Set(context.keys) == ["grantKey"], "query context changed unexpectedly")
        try require(context["grantKey"] as? String == fixtureGrant, "query context used the wrong synthetic grant")
        return query
    }

    private static func requestBodyData(_ request: URLRequest) throws -> Data {
        if let body = request.httpBody {
            return body
        }

        guard let stream = request.httpBodyStream else {
            throw ContractTestFailure(description: "request body was unavailable")
        }

        stream.open()
        defer { stream.close() }

        var body = Data()
        var buffer = [UInt8](repeating: 0, count: 4_096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count >= 0 else {
                throw ContractTestFailure(description: "request body stream could not be read")
            }
            guard count > 0 else { break }
            body.append(contentsOf: buffer.prefix(count))
        }

        guard !body.isEmpty else {
            throw ContractTestFailure(description: "request body was empty")
        }
        return body
    }

    private static func validateSearchQuery(
        _ query: [String: Any],
        searchValue: String,
        comparison: String,
        limit: Int
    ) throws {
        let organization = try dictionary(query["organization"], label: "organization")
        try require(Set(organization.keys) == ["$", "accounts"], "search organization selection changed")
        try validateOrganizationOptions(organization["$"])

        let accounts = try dictionary(organization["accounts"], label: "search accounts")
        try require(Set(accounts.keys) == ["$", "nodes"], "search accounts selection changed")

        let options = try dictionary(accounts["$"], label: "search accounts options")
        try require(Set(options.keys) == ["where", "size"], "search options changed")
        try require(options["size"] as? Int == limit, "search size changed")
        try validateWhereConditions(
            options["where"],
            expected: [
                ["name", comparison, searchValue],
                ["type", "=", "customer"]
            ],
            label: "search"
        )

        let nodes = try dictionary(accounts["nodes"], label: "search node selection")
        try require(Set(nodes.keys) == ["id", "name", "type"], "search node fields changed")
        try requireEmptySelections(nodes, labels: ["id", "name", "type"])
    }

    private static func validateDetailQuery(_ query: [String: Any], customerID: String) throws {
        let organization = try dictionary(query["organization"], label: "organization")
        try require(Set(organization.keys) == ["$", "accounts"], "detail organization selection changed")
        try validateOrganizationOptions(organization["$"])

        let accounts = try dictionary(organization["accounts"], label: "detail accounts")
        try require(Set(accounts.keys) == ["$", "nodes"], "detail accounts selection changed")

        let options = try dictionary(accounts["$"], label: "detail accounts options")
        try require(Set(options.keys) == ["where", "size"], "detail options changed")
        try require(options["size"] as? Int == 1, "detail size changed")
        try validateWhereConditions(
            options["where"],
            expected: [
                ["id", "=", customerID],
                ["type", "=", "customer"]
            ],
            label: "detail"
        )

        let nodes = try dictionary(accounts["nodes"], label: "detail node selection")
        try require(
            Set(nodes.keys) == [
                "id", "name", "type", "primaryLocation", "locations",
                "customFieldValues", "primaryContact", "contacts"
            ],
            "detail node fields changed"
        )
        try requireEmptySelections(nodes, labels: ["id", "name", "type"])
        try validateLocationSelection(nodes["primaryLocation"], label: "primary location")

        let locations = try dictionary(nodes["locations"], label: "locations connection")
        try require(Set(locations.keys) == ["$", "nodes"], "locations connection changed")
        let locationOptions = try dictionary(locations["$"], label: "locations options")
        try require(Set(locationOptions.keys) == ["size"], "locations options changed")
        try require(locationOptions["size"] as? Int == 1, "locations size changed")
        try validateLocationSelection(locations["nodes"], label: "fallback location")

        try validateCustomFieldValuesSelection(nodes["customFieldValues"], label: "account custom fields")
        try validateContactSelection(nodes["primaryContact"], label: "primary contact")

        let contacts = try dictionary(nodes["contacts"], label: "contacts connection")
        try require(Set(contacts.keys) == ["$", "nodes"], "contacts connection changed")
        let contactOptions = try dictionary(contacts["$"], label: "contacts options")
        try require(Set(contactOptions.keys) == ["size"], "contacts options changed")
        try require(contactOptions["size"] as? Int == 5, "contacts size changed")
        try validateContactSelection(contacts["nodes"], label: "related contact")
    }

    private static func validateOrganizationOptions(_ value: Any?) throws {
        let options = try dictionary(value, label: "organization options")
        try require(Set(options.keys) == ["id"], "organization options changed")
        try require(options["id"] as? String == fixtureOrganizationID, "request used the wrong synthetic organization")
    }

    private static func validateWhereConditions(
        _ value: Any?,
        expected: [[String]],
        label: String
    ) throws {
        let whereClause = try dictionary(value, label: "\(label) where clause")
        try require(Set(whereClause.keys) == ["and"], "\(label) where clause changed")
        guard let rawConditions = whereClause["and"] as? [Any] else {
            throw ContractTestFailure(description: "\(label) conditions were not an array")
        }

        let conditions = try rawConditions.map { value -> [String] in
            guard let condition = value as? [String], condition.count == 3 else {
                throw ContractTestFailure(description: "\(label) condition shape changed")
            }
            return condition
        }
        try require(conditions == expected, "\(label) condition values changed")
    }

    private static func validateLocationSelection(_ value: Any?, label: String) throws {
        let selection = try dictionary(value, label: label)
        let expectedKeys = ["id", "name", "address", "city", "state", "postalCode", "formattedAddress"]
        try require(Set(selection.keys) == Set(expectedKeys), "\(label) fields changed")
        try requireEmptySelections(selection, labels: expectedKeys)
    }

    private static func validateContactSelection(_ value: Any?, label: String) throws {
        let selection = try dictionary(value, label: label)
        let scalarKeys = ["id", "name", "firstName", "lastName", "title"]
        try require(Set(selection.keys) == Set(scalarKeys + ["customFieldValues"]), "\(label) fields changed")
        try requireEmptySelections(selection, labels: scalarKeys)
        try validateCustomFieldValuesSelection(selection["customFieldValues"], label: "\(label) custom fields")
    }

    private static func validateCustomFieldValuesSelection(_ value: Any?, label: String) throws {
        let connection = try dictionary(value, label: label)
        try require(Set(connection.keys) == ["$", "nodes"], "\(label) connection changed")
        let options = try dictionary(connection["$"], label: "\(label) options")
        try require(Set(options.keys) == ["size"], "\(label) options changed")
        try require(options["size"] as? Int == 20, "\(label) size changed")

        let nodes = try dictionary(connection["nodes"], label: "\(label) nodes")
        try require(Set(nodes.keys) == ["id", "value", "customField"], "\(label) node fields changed")
        try requireEmptySelections(nodes, labels: ["id", "value"])

        let customField = try dictionary(nodes["customField"], label: "\(label) definition")
        try require(Set(customField.keys) == ["id", "name", "type"], "\(label) definition fields changed")
        try requireEmptySelections(customField, labels: ["id", "name", "type"])
    }

    private static func requireEmptySelections(_ object: [String: Any], labels: [String]) throws {
        for label in labels {
            let selection = try dictionary(object[label], label: "\(label) selection")
            try require(selection.isEmpty, "\(label) is no longer an empty field selection")
        }
    }

    private static func dictionary(_ value: Any?, label: String) throws -> [String: Any] {
        guard let value = value as? [String: Any] else {
            throw ContractTestFailure(description: "\(label) was not an object")
        }
        return value
    }

    private static func fixtureData(_ json: String) -> Data {
        Data(json.utf8)
    }

    private static let emptySearchResponse =
        #"{"data":{"organization":{"accounts":{"nodes":[]}}},"errors":[]}"#

    private static let searchResultResponse =
        #"{"organization":{"accounts":{"nodes":[{"id":"fixture-customer-1","name":"Fixture Customer","type":"customer"}]}}}"#

    private static let customerDetailResponse = #"""
    {
      "data": {
        "organization": {
          "accounts": {
            "nodes": [
              {
                "id": "fixture-customer-1",
                "name": "Fixture Customer",
                "type": "customer",
                "primaryLocation": {
                  "id": "fixture-location-primary",
                  "name": "Fixture Location #99",
                  "address": "11000 Example Rd Unit 64",
                  "city": "Austin",
                  "state": "TX",
                  "postalCode": "78750",
                  "formattedAddress": "11000 Example Rd Unit 64, Austin, TX 78750, USA"
                },
                "locations": {
                  "nodes": [
                    {
                      "id": "fixture-location-fallback",
                      "name": "Fallback Location",
                      "address": "999 Fallback Ave",
                      "city": "Elsewhere",
                      "state": "CO",
                      "postalCode": "80000",
                      "formattedAddress": "999 Fallback Ave, Elsewhere, CO 80000, USA"
                    }
                  ]
                },
                "customFieldValues": {
                  "nodes": [
                    {
                      "id": "fixture-account-phone-value",
                      "value": " 512-555-0100 ",
                      "customField": {
                        "id": "fixture-account-phone-field",
                        "name": "Account Phone",
                        "type": "phoneNumber"
                      }
                    },
                    {
                      "id": "fixture-account-email-value",
                      "value": " account@example.invalid ",
                      "customField": {
                        "id": "fixture-account-email-field",
                        "name": "Account Email",
                        "type": "emailAddress"
                      }
                    }
                  ]
                },
                "primaryContact": {
                  "id": "fixture-primary-contact",
                  "name": "Fixture Primary Contact",
                  "firstName": "Fixture",
                  "lastName": "Primary",
                  "title": "Owner",
                  "customFieldValues": {
                    "nodes": [
                      {
                        "id": "fixture-primary-phone-value",
                        "value": " 512-555-0105 ",
                        "customField": {
                          "id": "fixture-primary-phone-field",
                          "name": "Phone",
                          "type": "phoneNumber"
                        }
                      },
                      {
                        "id": "fixture-primary-email-value",
                        "value": " primary@example.invalid ",
                        "customField": {
                          "id": "fixture-primary-email-field",
                          "name": "Email",
                          "type": "emailAddress"
                        }
                      }
                    ]
                  }
                },
                "contacts": {
                  "nodes": [
                    {
                      "id": "fixture-related-contact",
                      "name": "Fixture Related Contact",
                      "firstName": "Fixture",
                      "lastName": "Related",
                      "title": "Other",
                      "customFieldValues": {
                        "nodes": [
                          {
                            "id": "fixture-related-phone-value",
                            "value": "512-555-0199",
                            "customField": {
                              "id": "fixture-related-phone-field",
                              "name": "Phone",
                              "type": "phoneNumber"
                            }
                          },
                          {
                            "id": "fixture-related-email-value",
                            "value": "related@example.invalid",
                            "customField": {
                              "id": "fixture-related-email-field",
                              "name": "Email",
                              "type": "emailAddress"
                            }
                          }
                        ]
                      }
                    }
                  ]
                }
              }
            ]
          }
        }
      },
      "errors": []
    }
    """#

    private static let customerDetailPrimaryContactFallbackResponse = #"""
    {
      "organization": {
        "accounts": {
          "nodes": [
            {
              "id": "fixture-customer-1",
              "name": "Fixture Customer",
              "type": "customer",
              "primaryContact": {
                "id": "fixture-primary-fallback-contact",
                "name": "Fixture Primary Fallback Contact",
                "customFieldValues": {
                  "nodes": [
                    {
                      "id": "fixture-primary-fallback-phone-value",
                      "value": "720-555-0102",
                      "customField": {
                        "id": "fixture-primary-fallback-phone-field",
                        "name": "Phone",
                        "type": "phoneNumber"
                      }
                    },
                    {
                      "id": "fixture-primary-fallback-email-value",
                      "value": "primary-fallback@example.invalid",
                      "customField": {
                        "id": "fixture-primary-fallback-email-field",
                        "name": "Email",
                        "type": "emailAddress"
                      }
                    }
                  ]
                }
              },
              "contacts": {
                "nodes": [
                  {
                    "id": "fixture-related-after-primary-contact",
                    "name": "Fixture Related After Primary Contact",
                    "customFieldValues": {
                      "nodes": [
                        {
                          "id": "fixture-related-after-primary-phone-value",
                          "value": "720-555-0199",
                          "customField": {
                            "id": "fixture-related-after-primary-phone-field",
                            "name": "Phone",
                            "type": "phoneNumber"
                          }
                        },
                        {
                          "id": "fixture-related-after-primary-email-value",
                          "value": "related-after-primary@example.invalid",
                          "customField": {
                            "id": "fixture-related-after-primary-email-field",
                            "name": "Email",
                            "type": "emailAddress"
                          }
                        }
                      ]
                    }
                  }
                ]
              }
            }
          ]
        }
      },
      "errors": []
    }
    """#

    private static let customerDetailFallbackResponse = #"""
    {
      "data": {
        "organization": {
          "accounts": {
            "nodes": [
              {
                "id": "fixture-customer-1",
                "name": "Fixture Customer",
                "type": "customer",
                "locations": {
                  "nodes": [
                    {
                      "id": "fixture-location-fallback-only",
                      "name": "Fallback Location",
                      "address": "22000 Fallback Rd #5",
                      "city": "Boulder",
                      "state": "CO",
                      "postalCode": "80301",
                      "formattedAddress": "22000 Fallback Rd #5, Boulder, CO 80301, USA"
                    }
                  ]
                },
                "contacts": {
                  "nodes": [
                    {
                      "id": "fixture-related-fallback-contact",
                      "name": "Fixture Fallback Contact",
                      "customFieldValues": {
                        "nodes": [
                          {
                            "id": "fixture-related-fallback-phone-value",
                            "value": "303-555-0101",
                            "customField": {
                              "id": "fixture-related-fallback-phone-field",
                              "name": "Phone",
                              "type": "phoneNumber"
                            }
                          },
                          {
                            "id": "fixture-related-fallback-email-value",
                            "value": "fallback@example.invalid",
                            "customField": {
                              "id": "fixture-related-fallback-email-field",
                              "name": "Email",
                              "type": "emailAddress"
                            }
                          }
                        ]
                      }
                    }
                  ]
                }
              }
            ]
          }
        }
      },
      "errors": []
    }
    """#

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else {
            throw ContractTestFailure(description: message)
        }
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("JobTread read contract verification failed: \(message)\n".utf8))
        Foundation.exit(1)
    }
}
