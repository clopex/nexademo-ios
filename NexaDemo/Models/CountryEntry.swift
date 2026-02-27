import Foundation

struct CountryEntry: Identifiable, Hashable, Sendable {
    let name: String
    let code: String
    let dialCodes: [String]

    var id: String { code }
}
