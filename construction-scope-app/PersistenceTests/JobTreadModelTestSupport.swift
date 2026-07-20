import Foundation

struct JobTreadCustomerDetail: Sendable {
    let customerID: String
    let displayName: String?
    let accountType: String?
    let primaryAddress: String?
    let unitNumber: String?
    let city: String?
    let state: String?
    let postalCode: String?
    let phone: String?
    let email: String?
}
