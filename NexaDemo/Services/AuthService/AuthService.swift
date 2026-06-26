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
        do {
            return try await performGetMe()
        } catch let error as NetworkClientError {
            guard case .serverError(let statusCode, _) = error, statusCode == 401 || statusCode == 403 else {
                throw error
            }

            _ = try await refreshSession()
            return try await performGetMe()
        }
    }

    func refreshSession() async throws -> AuthResponse {
        guard let refreshToken = await KeychainService.shared.getRefreshToken() else {
            throw NetworkClientError.missingToken
        }

        let url = client.url(for: "auth/refresh")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            RefreshTokenRequest(refreshToken: refreshToken)
        )

        let response: AuthResponse = try await client.performRequest(request)
        await KeychainService.shared.saveSession(token: response.token, refreshToken: response.refreshToken)
        return response
    }

    private func performGetMe() async throws -> User {
        let url = client.url(for: "auth/me")
        var request = URLRequest(url: url)
        let accessToken = try await accessToken()
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let response: MeResponse = try await client.performRequest(request)
        return response.user
    }

    private func accessToken() async throws -> String {
        if let token = await KeychainService.shared.getToken() {
            return token
        }

        let response = try await refreshSession()
        return response.token
    }
}
