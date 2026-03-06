import Foundation
import Observation
import LocalAuthentication

@MainActor
@Observable
final class AuthViewModel {
    var currentUser: User?
    var isLoggedIn = false
    var needsProfileSetup = false
    var isBootstrapping = true
    var isLoading = false
    var isBiometricLoginAvailable = false
    var errorMessage: String?

    init() {
        let defaults = UserDefaults.standard
        let shouldClear = !defaults.bool(forKey: "hasLaunchedBefore")
        if shouldClear { defaults.set(true, forKey: "hasLaunchedBefore") }

        Task {
            await launchSequence(shouldClear: shouldClear)
        }
    }

    func register(fullName: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await AuthService.shared.register(fullName: fullName, email: email, password: password)
            await KeychainService.shared.saveToken(response.token)
            BiometricAuthService.setLoginPending(false)
            currentUser = response.user
            isLoggedIn = true
            needsProfileSetup = true
            await refreshBiometricLoginAvailability()
        } catch {
            setError(error)
        }

        isLoading = false
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await AuthService.shared.login(email: email, password: password)
            await KeychainService.shared.saveToken(response.token)
            BiometricAuthService.setLoginPending(false)
            currentUser = response.user
            isLoggedIn = true
            needsProfileSetup = false
            await refreshBiometricLoginAvailability()
        } catch {
            setError(error)
        }

        isLoading = false
    }
    
    func googleLogin(googleId: String, email: String, fullName: String, profilePicture: String?) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await AuthService.shared.googleLogin(googleId: googleId, email: email, fullName: fullName, profilePicture: profilePicture)
            await KeychainService.shared.saveToken(response.token)
            BiometricAuthService.setLoginPending(false)
            currentUser = response.user
            isLoggedIn = true
            needsProfileSetup = false
            await refreshBiometricLoginAvailability()
        } catch {
            setError(error)
        }

        isLoading = false
    }

    func appleLogin(appleId: String, email: String?, fullName: String?) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await AuthService.shared.appleLogin(appleId: appleId, email: email, fullName: fullName)
            await KeychainService.shared.saveToken(response.token)
            BiometricAuthService.setLoginPending(false)
            currentUser = response.user
            isLoggedIn = true
            needsProfileSetup = false
            await refreshBiometricLoginAvailability()
        } catch {
            setError(error)
        }

        isLoading = false
    }

    func loadCurrentUser() async {
        do {
            currentUser = try await AuthService.shared.getMe()
            isLoggedIn = true
            needsProfileSetup = false
        } catch {
            await KeychainService.shared.deleteToken()
            BiometricAuthService.setLoginPending(false)
            currentUser = nil
            isLoggedIn = false
            needsProfileSetup = false
        }

        await refreshBiometricLoginAvailability()
    }

    func biometricLogin() async {
        isLoading = true
        errorMessage = nil

        do {
            guard BiometricAuthService.isEnabled() else {
                throw BiometricAuthError.biometricDisabled
            }

            guard await KeychainService.shared.getToken() != nil else {
                throw BiometricAuthError.missingToken
            }

            let biometryName = switch BiometricAuthService.biometryType() {
            case .faceID: "Face ID"
            case .touchID: "Touch ID"
            default: "Biometric"
            }

            try await BiometricAuthService.authenticate(
                reason: "Use \(biometryName) to log in to NexaDemo."
            )

            BiometricAuthService.setLoginPending(false)
            await loadCurrentUser()

            if !isLoggedIn {
                throw BiometricAuthError.invalidSession
            }
        } catch {
            setError(error)
            await refreshBiometricLoginAvailability()
        }

        isLoading = false
    }

    func refreshBiometricLoginAvailability() async {
        let hasToken = await KeychainService.shared.getToken() != nil
        isBiometricLoginAvailable = BiometricAuthService.isEnabled() && hasToken
    }

    func logout() {
        let shouldKeepToken = BiometricAuthService.isEnabled()

        if shouldKeepToken {
            BiometricAuthService.setLoginPending(true)
            isBiometricLoginAvailable = true
        } else {
            isBiometricLoginAvailable = false
            Task { await KeychainService.shared.deleteToken() }
        }

        currentUser = nil
        isLoggedIn = false
        needsProfileSetup = false
    }

    private func launchSequence(shouldClear: Bool) async {
        isBootstrapping = true
        if shouldClear {
            await KeychainService.shared.deleteToken()
            BiometricAuthService.setLoginPending(false)
        }

        let hasToken = await KeychainService.shared.getToken() != nil
        isBiometricLoginAvailable = BiometricAuthService.isEnabled() && hasToken

        guard hasToken else {
            currentUser = nil
            isLoggedIn = false
            needsProfileSetup = false
            isBootstrapping = false
            return
        }

        if BiometricAuthService.isLoginPending() {
            currentUser = nil
            isLoggedIn = false
            needsProfileSetup = false
            isBootstrapping = false
            return
        }

        await loadCurrentUser()
        isBootstrapping = false
    }

    private func setError(_ error: Error) {
        if let apiError = error as? LocalizedError, let message = apiError.errorDescription {
            errorMessage = message
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
