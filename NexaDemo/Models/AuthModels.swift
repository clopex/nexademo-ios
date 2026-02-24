import Foundation

struct AuthResponse: Codable, Sendable {
    let message: String
    let token: String
    let user: User
}

struct MeResponse: Codable, Sendable {
    let user: User
}

struct APIError: Codable, Sendable {
    let error: String
}

struct RegisterRequest: Codable, Sendable {
    let fullName: String
    let email: String
    let password: String
}

struct LoginRequest: Codable, Sendable {
    let email: String
    let password: String
}

struct GoogleLoginRequest: Encodable, Sendable {
    let googleId: String
    let email: String
    let fullName: String
    let profilePicture: String?
}

struct AppleLoginRequest: Encodable, Sendable {
    let appleId: String
    let email: String?
    let fullName: String?
}
