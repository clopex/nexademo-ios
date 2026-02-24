import Foundation
import Observation

@MainActor
@Observable
final class AuthViewModel {
    var currentUser: User?
    var isLoggedIn = false
    var isLoading = false
    var errorMessage: String?

    init() {
        Task { @MainActor in
            await loadCurrentUser()
        }
    }

    func register(fullName: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIService.shared.register(fullName: fullName, email: email, password: password)
            await KeychainService.shared.saveToken(response.token)
            currentUser = response.user
            isLoggedIn = true
        } catch {
            setError(error)
        }

        isLoading = false
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIService.shared.login(email: email, password: password)
            await KeychainService.shared.saveToken(response.token)
            currentUser = response.user
            isLoggedIn = true
        } catch {
            setError(error)
        }

        isLoading = false
    }
    
    func googleLogin(googleId: String, email: String, fullName: String, profilePicture: String?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.googleLogin(googleId: googleId, email: email, fullName: fullName, profilePicture: profilePicture)
            await KeychainService.shared.saveToken(response.token)
            currentUser = response.user
            isLoggedIn = true
        } catch {
            setError(error)
        }
    }

    func appleLogin(appleId: String, email: String?, fullName: String?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.appleLogin(appleId: appleId, email: email, fullName: fullName)
            await KeychainService.shared.saveToken(response.token)
            currentUser = response.user
            isLoggedIn = true
        } catch {
            setError(error)
        }
    }

    func loadCurrentUser() async {
        do {
            currentUser = try await APIService.shared.getMe()
            isLoggedIn = true
        } catch {
            logout()
        }
    }

    func logout() {
        Task { await KeychainService.shared.deleteToken() }
        currentUser = nil
        isLoggedIn = false
    }

    private func setError(_ error: Error) {
        if let apiError = error as? LocalizedError, let message = apiError.errorDescription {
            errorMessage = message
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
