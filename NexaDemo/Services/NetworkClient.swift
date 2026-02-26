import Foundation

enum NetworkClientError: LocalizedError, Sendable {
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

struct NetworkClient: Sendable {
    static let shared = NetworkClient()

    private let baseURL: URL = NetworkClient.loadBaseURL()

    static func loadBaseURL() -> URL {
        if let value = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           let url = URL(string: value) {
            return url
        }
        return URL(string: "https://nexademo-backend.onrender.com/api")!
    }

    func url(for path: String) -> URL {
        baseURL.appending(path: path)
    }

    func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkClientError.invalidResponse
        }

        if (200...299).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode(T.self, from: data)
        }

        let message = (try? JSONDecoder().decode(APIError.self, from: data))?.error
            ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)

        throw NetworkClientError.serverError(statusCode: httpResponse.statusCode, message: message)
    }
}
