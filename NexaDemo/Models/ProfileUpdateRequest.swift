import Foundation

struct ProfileUpdateRequest: Encodable, Sendable {
    let fullName: String?
    let email: String?
    let gender: String?
    let phone: String?
    let country: String?
    let city: String?
    let address: String?
    let profilePicture: String?
}
