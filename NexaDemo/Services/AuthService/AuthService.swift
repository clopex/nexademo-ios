import Foundation

struct AuthService: Sendable {
    static let shared = AuthService()
    private let client = NetworkClient.shared

    func register(fullName: String, email: String, password: String) async throws -> AuthResponse {
        let url = client.url(for: "auth/register")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            RegisterRequest(fullName: fullName, email: email, password: password)
        )

        return try await client.performRequest(request)
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let url = client.url(for: "auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            LoginRequest(email: email, password: password)
        )

        return try await client.performRequest(request)
    }

    func googleLogin(googleId: String, email: String, fullName: String, profilePicture: String?) async throws -> AuthResponse {
        let url = client.url(for: "auth/google")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            GoogleLoginRequest(googleId: googleId, email: email, fullName: fullName, profilePicture: profilePicture)
        )

        return try await client.performRequest(request)
    }

    func appleLogin(appleId: String, email: String?, fullName: String?) async throws -> AuthResponse {
        let url = client.url(for: "auth/apple")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            AppleLoginRequest(appleId: appleId, email: email, fullName: fullName)
        )

        return try await client.performRequest(request)
    }

    func getMe() async throws -> User {
        let url = client.url(for: "auth/me")
        var request = URLRequest(url: url)
        if let token = await KeychainService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NetworkClientError.missingToken
        }

        let response: MeResponse = try await client.performRequest(request)
        return response.user
    }
}
