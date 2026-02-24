import Foundation

struct User: Codable, Identifiable, Sendable {
    let id: String
    let fullName: String
    let email: String
    let isPremium: Bool
}
