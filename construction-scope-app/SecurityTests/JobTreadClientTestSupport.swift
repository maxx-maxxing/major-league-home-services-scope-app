import Foundation

struct JobTreadCustomerLookupResult: Sendable {
    let customerID: String
    let displayName: String?
    let accountType: String?
    let primaryAddress: String?
    let phone: String?
    let email: String?
}

extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
