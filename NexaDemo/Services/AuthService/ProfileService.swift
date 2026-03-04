import Foundation

struct ProfileService: Sendable {
    static let shared = ProfileService()
    private let client = NetworkClient.shared

    func updateProfile(_ payload: ProfileUpdateRequest) async throws -> User {
        let url = client.url(for: "auth/profile")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = await KeychainService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NetworkClientError.missingToken
        }
        request.httpBody = try JSONEncoder().encode(payload)

        let response: ProfileResponse = try await client.performRequest(request)
        return response.user
    }
}
