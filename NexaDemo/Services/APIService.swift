import Foundation

enum APIServiceError: LocalizedError, Sendable {
    case missingToken
    case invalidResponse
    case serverError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Nedostaje token. Prijavi se ponovo."
        case .invalidResponse:
            return "Neispravan odgovor servera."
        case .serverError(_, let message):
            return message
        }
    }
}

struct APIService: Sendable {
    static let shared = APIService()

    private let baseURL: URL = APIService.loadBaseURL()

    static func loadBaseURL() -> URL {
        if let value = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           let url = URL(string: value) {
            return url
        }
        return URL(string: "https://nexademo-backend.onrender.com/api")!
    }

    func register(fullName: String, email: String, password: String) async throws -> AuthResponse {
        let url = baseURL.appendingPathComponent("auth/register")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            RegisterRequest(fullName: fullName, email: email, password: password)
        )

        return try await performRequest(request)
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let url = baseURL.appendingPathComponent("auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            LoginRequest(email: email, password: password)
        )

        return try await performRequest(request)
    }
    
    func googleLogin(googleId: String, email: String, fullName: String, profilePicture: String?) async throws -> AuthResponse {
        let url = baseURL.appendingPathComponent("auth/google")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            GoogleLoginRequest(googleId: googleId, email: email, fullName: fullName, profilePicture: profilePicture)
        )
        return try await performRequest(request)
    }

    func appleLogin(appleId: String, email: String?, fullName: String?) async throws -> AuthResponse {
        let url = baseURL.appendingPathComponent("auth/apple")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            AppleLoginRequest(appleId: appleId, email: email, fullName: fullName)
        )
        return try await performRequest(request)
    }

    func getMe() async throws -> User {
        let url = baseURL.appendingPathComponent("auth/me")
        var request = URLRequest(url: url)
        if let token = await KeychainService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw APIServiceError.missingToken
        }

        let response: MeResponse = try await performRequest(request)
        return response.user
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIServiceError.invalidResponse
        }

        if (200...299).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode(T.self, from: data)
        }

        let message = (try? JSONDecoder().decode(APIError.self, from: data))?.error
            ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)

        throw APIServiceError.serverError(statusCode: httpResponse.statusCode, message: message)
    }
}
