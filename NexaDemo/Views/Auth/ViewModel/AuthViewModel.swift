import Foundation
import Observation
import LocalAuthentication

@MainActor
@Observable
final class AuthViewModel {
    private static let pendingProfileSetupUserIDsKey = "pendingProfileSetupUserIDs"
    private static let completedProfileSetupUserIDsKey = "completedProfileSetupUserIDs"

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
            await beginAuthenticatedSession(with: response, requiresProfileSetup: true)
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
            await beginAuthenticatedSession(with: response, requiresProfileSetup: false)
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
            await beginAuthenticatedSession(with: response, requiresProfileSetup: false)
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
            await beginAuthenticatedSession(with: response, requiresProfileSetup: true)
        } catch {
            setError(error)
        }

        isLoading = false
    }

    func loadCurrentUser() async {
        do {
            let user = try await AuthService.shared.getMe()
            currentUser = user
            isLoggedIn = true
            needsProfileSetup = isProfileSetupPending(for: user.id)
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

    func logout() async {
        let shouldKeepToken = BiometricAuthService.isEnabled()

        if shouldKeepToken {
            BiometricAuthService.setLoginPending(true)
            isBiometricLoginAvailable = true
        } else {
            isBiometricLoginAvailable = false
            await KeychainService.shared.deleteToken()
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
    
    func completeProfileSetup(with user: User) {
        currentUser = user
        markProfileSetupCompleted(for: user.id)
        clearProfileSetupPending(for: user.id)
        needsProfileSetup = false
    }
    
    private func beginAuthenticatedSession(with response: AuthResponse, requiresProfileSetup: Bool) async {
        await KeychainService.shared.saveToken(response.token)
        BiometricAuthService.setLoginPending(false)

        let user = await loadCanonicalUser(fallback: response.user)
        currentUser = user
        isLoggedIn = true
        if requiresProfileSetup && hasCompletedProfileSetup(for: user.id) == false {
            markProfileSetupPending(for: user.id)
        }
        needsProfileSetup = isProfileSetupPending(for: user.id)

        await refreshBiometricLoginAvailability()
    }
    
    private func loadCanonicalUser(fallback fallbackUser: User) async -> User {
        do {
            return try await AuthService.shared.getMe()
        } catch {
            return fallbackUser
        }
    }
    
    private func isProfileSetupPending(for userID: String) -> Bool {
        pendingProfileSetupUserIDs().contains(userID)
    }
    
    private func normalized(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), trimmed.isEmpty == false else {
            return nil
        }
        return trimmed
    }
    
    private func pendingProfileSetupUserIDs() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: Self.pendingProfileSetupUserIDsKey) ?? [])
    }
    
    private func completedProfileSetupUserIDs() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: Self.completedProfileSetupUserIDsKey) ?? [])
    }
    
    private func hasCompletedProfileSetup(for userID: String) -> Bool {
        completedProfileSetupUserIDs().contains(userID)
    }
    
    private func markProfileSetupPending(for userID: String) {
        var userIDs = pendingProfileSetupUserIDs()
        userIDs.insert(userID)
        UserDefaults.standard.set(Array(userIDs), forKey: Self.pendingProfileSetupUserIDsKey)
    }
    
    private func markProfileSetupCompleted(for userID: String) {
        var userIDs = completedProfileSetupUserIDs()
        userIDs.insert(userID)
        UserDefaults.standard.set(Array(userIDs), forKey: Self.completedProfileSetupUserIDsKey)
    }
    
    private func clearProfileSetupPending(for userID: String) {
        var userIDs = pendingProfileSetupUserIDs()
        userIDs.remove(userID)
        UserDefaults.standard.set(Array(userIDs), forKey: Self.pendingProfileSetupUserIDsKey)
    }

    private func setError(_ error: Error) {
        if let apiError = error as? LocalizedError, let message = apiError.errorDescription {
            errorMessage = message
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
