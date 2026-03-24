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
        return URL(string: "https://nexademo-backend-production.up.railway.app/api")!
    }

    func url(for path: String) -> URL {
        baseURL.appending(path: path)
    }

    func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data = try await performRequestData(request)
        let bodyString = String(data: data, encoding: .utf8) ?? "<empty>"
        let urlString = request.url?.absoluteString ?? "unknown"

        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            print("Network success \(urlString)")
            return decoded
        } catch {
            print("Network decode error \(urlString) body: \(bodyString)")
            throw error
        }
    }

    func performRequestWithoutResponse(_ request: URLRequest) async throws {
        _ = try await performRequestData(request)
    }

    func performDataRequest(_ request: URLRequest) async throws -> Data {
        try await performRequestData(request)
    }

    private func performRequestData(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkClientError.invalidResponse
        }

        let urlString = request.url?.absoluteString ?? "unknown"
        let bodyString = String(data: data, encoding: .utf8) ?? "<empty>"

        if (200...299).contains(httpResponse.statusCode) {
            print("Network success [\(httpResponse.statusCode)] \(urlString)")
            return data
        }

        print("Network error [\(httpResponse.statusCode)] \(urlString) body: \(bodyString)")

        let message = (try? JSONDecoder().decode(APIError.self, from: data))?.error
            ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)

        throw NetworkClientError.serverError(statusCode: httpResponse.statusCode, message: message)
    }
}
