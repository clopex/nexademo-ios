//
//  StripeService.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 4. 3. 2026..
//

import Foundation
import StripePaymentSheet
import UIKit

@Observable
@MainActor
final class StripeService {
    var isLoading = false
    var errorMessage: String?
    var paymentResult: PaymentSheetResult?
    private(set) var lastPaymentIntentId: String?
    private let client = NetworkClient.shared
    private let publishableKey = "pk_test_51T7ILwJLY1F2Nyv2fpcvO7gw8vvWAt3eTi4RacCqYt6EpPe1mMpLyXaQpSqVdWO1oPNQGrGvkS6CNga1YsEMxHwY00vwFQvkVS"

    init() {
        StripeAPI.defaultPublishableKey = publishableKey
    }

    func startPayment(from viewController: UIViewController) async {
        isLoading = true
        errorMessage = nil

        do {
            let clientSecret = try await fetchPaymentIntent()
            var config = PaymentSheet.Configuration()
            config.merchantDisplayName = "NexaDemo"
            config.allowsDelayedPaymentMethods = false
            config.primaryButtonColor = UIColor(red: 0.91, green: 0.27, blue: 0.38, alpha: 1)

            let paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config)

            await withCheckedContinuation { continuation in
                paymentSheet.present(from: viewController) { [weak self] result in
                    Task { @MainActor [weak self] in
                        self?.paymentResult = result
                        self?.isLoading = false
                        continuation.resume()
                    }
                }
            }

        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func confirmCompletedPayment() async throws {
        guard let intentId = lastPaymentIntentId else { return }

        let url = client.url(for: "payments/confirm")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = await KeychainService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw StripeServiceError.missingToken
        }

        request.httpBody = try JSONEncoder().encode(
            ConfirmPaymentRequest(paymentIntentId: intentId)
        )

        try await client.performRequestWithoutResponse(request)
    }

    private func fetchPaymentIntent() async throws -> String {
        let url = client.url(for: "payments/create-intent")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = await KeychainService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw StripeServiceError.missingToken
        }

        let result: PaymentIntentResponse = try await client.performRequest(request)
        let clientSecret = result.clientSecret
        lastPaymentIntentId = clientSecret.components(separatedBy: "_secret_").first
        return clientSecret
    }
}

enum StripeServiceError: LocalizedError {
    case missingToken
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .missingToken: return "Missing auth token"
        case .serverError(let msg): return msg
        }
    }
}

private struct PaymentIntentResponse: Decodable {
    let clientSecret: String
    let amount: Int
}

private struct ConfirmPaymentRequest: Encodable {
    let paymentIntentId: String
}
