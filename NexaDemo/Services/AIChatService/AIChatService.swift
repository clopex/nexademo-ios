import Foundation

struct AIChatService: Sendable {
    static let shared = AIChatService()
    private let client = NetworkClient.shared

    func sendChatMessage(_ message: String) async throws -> String {
        var request = URLRequest(url: client.url(for: "ai/chat"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = await KeychainService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NetworkClientError.missingToken
        }

        request.httpBody = try JSONEncoder().encode(ChatMessageRequest(message: message))
        let response: ChatResponse = try await client.performRequest(request)
        return response.reply
    }

    func getChatHistory() async throws -> [ChatMessageModel] {
        var request = URLRequest(url: client.url(for: "ai/chat/history"))
        request.httpMethod = "GET"

        if let token = await KeychainService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NetworkClientError.missingToken
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode(APIError.self, from: data))?.error
                ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw NetworkClientError.serverError(statusCode: httpResponse.statusCode, message: message)
        }

        if let wrapped = try? decoder.decode(ChatHistoryResponse.self, from: data) {
            return wrapped.messages
        }
        if let plain = try? decoder.decode([ChatMessageModel].self, from: data) {
            return plain
        }
        throw NetworkClientError.invalidResponse
    }

    func clearChatHistory() async throws {
        var request = URLRequest(url: client.url(for: "ai/chat/history"))
        request.httpMethod = "DELETE"

        if let token = await KeychainService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NetworkClientError.missingToken
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode(APIError.self, from: data))?.error
                ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw NetworkClientError.serverError(statusCode: httpResponse.statusCode, message: message)
        }
    }
}

private struct ChatMessageRequest: Encodable, Sendable {
    let message: String
}
