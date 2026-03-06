import Foundation
import LocalAuthentication

enum BiometricAuthError: LocalizedError {
    case biometricDisabled
    case missingToken
    case unavailable
    case invalidSession

    var errorDescription: String? {
        switch self {
        case .biometricDisabled:
            return "Biometric login is turned off."
        case .missingToken:
            return "Your saved session is no longer available. Please log in with email and password."
        case .unavailable:
            return "Biometric authentication is not available on this device."
        case .invalidSession:
            return "Your session expired. Please log in again."
        }
    }
}

enum BiometricAuthService {
    private static let enabledKey = "biometricEnabled"
    private static let emailKey = "biometricEmail"
    private static let pendingLoginKey = "biometricLoginPending"

    static func isEnabled(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: enabledKey)
    }

    static func enable(email: String?, defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: enabledKey)
        defaults.set(false, forKey: pendingLoginKey)

        if let email, !email.isEmpty {
            defaults.set(email, forKey: emailKey)
        }
    }

    static func disable(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: enabledKey)
        defaults.removeObject(forKey: emailKey)
        defaults.removeObject(forKey: pendingLoginKey)
    }

    static func isLoginPending(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: pendingLoginKey)
    }

    static func setLoginPending(_ isPending: Bool, defaults: UserDefaults = .standard) {
        defaults.set(isPending, forKey: pendingLoginKey)
    }

    static func biometryType() -> LABiometryType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        return context.biometryType
    }

    static func authenticate(reason: String) async throws {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw error ?? BiometricAuthError.unavailable
        }

        _ = try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        )
    }
}
