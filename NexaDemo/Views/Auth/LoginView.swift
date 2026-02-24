import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var goToEmail = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.95, green: 0.95, blue: 0.97).ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer().frame(height: 32)

                    VStack(spacing: 8) {
                        Text("Privacy by design")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.black.opacity(0.85))
                        Text("We never sell or share your information with\nthird parties.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 240, height: 240)
                        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)

                    Spacer()

                    VStack(spacing: 14) {
                        TermsText()
                            .padding(.horizontal, 24)

                        AppleAuthButton()

                        NavigationLink(destination: EmailLoginView().environment(authVM), isActive: $goToEmail) {
                            EmptyView()
                        }
                        .hidden()

                        Button { goToEmail = true } label: {
                            Text("Use email instead")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 2)
                    }

                    Spacer().frame(height: 20)
                }
            }
        }
    }
}

// MARK: - Components

private struct TermsText: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("For more details, please refer to our")
                .font(.footnote)
                .foregroundColor(.gray)
            HStack(spacing: 6) {
                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                    .font(.footnote.weight(.semibold))
                    .underline()
                Text("and")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    .font(.footnote.weight(.semibold))
                    .underline()
            }
        }
        .multilineTextAlignment(.center)
    }
}

private struct AppleAuthButton: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        SignInWithAppleButton(.continue) { _ in
            // Request configuration left default
        } onCompletion: { result in
            Task { @MainActor in
                switch result {
                case .success(let auth):
                    handleSuccess(auth)
                case .failure(let error):
                    authVM.errorMessage = error.localizedDescription
                }
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 52)
        .cornerRadius(26)
        .padding(.horizontal, 24)
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 8)
    }

    private func handleSuccess(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let email = credential.email ?? ""
        let tokenString: String? = {
            guard let data = credential.identityToken else { return nil }
            return String(data: data, encoding: .utf8)
        }()

        let user = User(id: credential.user, fullName: fullName.isEmpty ? "Apple User" : fullName, email: email, isPremium: false)
        authVM.currentUser = user
        authVM.isLoggedIn = true
        if let token = tokenString {
            Task { await KeychainService.shared.saveToken(token) }
        }
    }
}

private struct EmailLoginView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false

    var body: some View {
        Form {
            Section {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                SecureField("Password", text: $password)
            }

            if let error = authVM.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            Section {
                Button {
                    Task { await authVM.login(email: email, password: password) }
                } label: {
                    if authVM.isLoading {
                        ProgressView()
                    } else {
                        Text("Sign in")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)

                Button("Create account") {
                    showRegister = true
                }
            }
        }
        .navigationTitle("Use email")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRegister) {
            RegisterView()
                .environment(authVM)
        }
    }
}
