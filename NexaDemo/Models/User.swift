import Foundation

struct User: Codable, Identifiable, Sendable {
    let id: String
    let fullName: String
    let email: String
    let isPremium: Bool?
    let gender: String?
    let phone: String?
    let country: String?
    let city: String?
    let address: String?
    let profilePicture: String?
    let googleId: String?
    let appleId: String?
}
