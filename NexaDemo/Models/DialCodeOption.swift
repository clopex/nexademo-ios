import Foundation

struct DialCodeOption: Identifiable, Hashable, Sendable {
    let countryName: String
    let countryCode: String
    let dialCode: String

    var id: String { "\(countryCode)-\(dialCode)" }
}
