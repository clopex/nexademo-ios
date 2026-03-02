import Foundation


struct TipsService: Sendable {
    func fetchDailyTip() async throws -> DailyTipResponse {
        var request = URLRequest(url: NetworkClient.shared.url(for: "tips/daily"))
        request.httpMethod = "GET"
        if let token = await KeychainService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NetworkClientError.missingToken
        }
        return try await NetworkClient.shared.performRequest(request)
    }
}
