import FamilyControls
import Foundation

struct FocusAuthorizationService: Sendable {
    func authorizationStatus() -> AuthorizationStatus {
        AuthorizationCenter.shared.authorizationStatus
    }

    func requestAuthorizationIfNeeded() async throws {
        let center = AuthorizationCenter.shared

        switch center.authorizationStatus {
        case .approved:
            return
        case .notDetermined:
            try await center.requestAuthorization(for: .individual)
        case .denied:
            throw FocusSessionError.authorizationDenied
        @unknown default:
            throw FocusSessionError.unavailable
        }
    }
}
