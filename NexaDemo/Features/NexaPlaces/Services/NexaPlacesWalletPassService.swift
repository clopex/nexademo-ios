import Foundation
import PassKit

struct NexaPlacesWalletPassService: Sendable {
    private let client = NetworkClient.shared

    func fetchPass(for requestBody: NexaPlaceWalletPassRequest) async throws -> PKPass {
        guard PKAddPassesViewController.canAddPasses() else {
            throw NexaPlacesWalletPassServiceError.walletUnavailable
        }

        let token = await KeychainService.shared.getToken()
        guard let token else {
            throw NexaPlacesWalletPassServiceError.missingToken
        }

        var request = URLRequest(url: client.url(for: "places/wallet-pass"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/vnd.apple.pkpass", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let passData = try await client.performDataRequest(request)

        do {
            return try PKPass(data: passData)
        } catch {
            throw NexaPlacesWalletPassServiceError.invalidPassData
        }
    }
}

enum NexaPlacesWalletPassServiceError: LocalizedError {
    case walletUnavailable
    case missingToken
    case invalidPassData

    var errorDescription: String? {
        switch self {
        case .walletUnavailable:
            return "Apple Wallet is not available on this device."
        case .missingToken:
            return "Nedostaje token. Prijavi se ponovo."
        case .invalidPassData:
            return "Server nije vratio validan Wallet pass."
        }
    }
}
