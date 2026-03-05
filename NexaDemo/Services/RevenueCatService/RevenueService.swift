//
//  RevenueService.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 5. 3. 2026..
//

import Foundation
import RevenueCat

@Observable
@MainActor
final class RevenueCatService {
    var isPremium = false
    var isLoading = false
    var errorMessage: String?
    var offerings: Offerings?
    private let client = NetworkClient.shared
    private let entitlementID = "NexaDemo Pro"
    private let apiKey = "test_TWxBCdsIjwAqrALqeZAOBLLHpch"

    func configure(userId: String) {
        Purchases.configure(withAPIKey: apiKey, appUserID: userId)
        Purchases.shared.delegate = PurchasesDelegateHandler.shared
    }

    func fetchOfferings() async {
        isLoading = true
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func purchase(package: Package) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Purchases.shared.purchase(package: package)
            let entitlementActive = result.customerInfo.entitlements[entitlementID]?.isActive ?? false
            // Za Test Store — ako userCancelled je false, smatraj uspješnim
            isPremium = entitlementActive || !result.userCancelled
            isLoading = false
            return isPremium
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func restorePurchases() async {
        isLoading = true
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            isPremium = customerInfo.entitlements[entitlementID]?.isActive ?? false
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func checkPremiumStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            isPremium = customerInfo.entitlements[entitlementID]?.isActive ?? false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func activatePremium() async throws -> User {
        let url = client.url(for: "payments/activate-premium")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = await KeychainService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NetworkClientError.missingToken
        }

        let response: ActivatePremiumResponse = try await client.performRequest(request)
        return response.user
    }
}

// MARK: - Purchases Delegate
final class PurchasesDelegateHandler: NSObject, PurchasesDelegate, @unchecked Sendable {
    static let shared = PurchasesDelegateHandler()
    private let entitlementID = "NexaDemo Pro"

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            NotificationCenter.default.post(
                name: .premiumStatusChanged,
                object: customerInfo.entitlements[entitlementID]?.isActive ?? false
            )
        }
    }
}

extension Notification.Name {
    static let premiumStatusChanged = Notification.Name("premiumStatusChanged")
}

private struct ActivatePremiumResponse: Decodable {
    let message: String
    let user: User
}
