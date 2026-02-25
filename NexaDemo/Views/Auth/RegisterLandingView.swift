import SwiftUI
import AuthenticationServices

struct RegisterLandingView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(AuthRouter.self) private var authRouter

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 80)

                VStack(spacing: 8) {
                    Text("Privacy by design")
                        .font(.title2.bold())
                        .foregroundStyle(.black.opacity(0.85))
                    Text("We never sell or share your information with\nthird parties.")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer()

                Image(systemName: "lock.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .gray.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: .black.opacity(0.16), radius: 10, x: 0, y: 0)

                Spacer()

                VStack(spacing: 8) {
                    TermsText()
                        .padding([.horizontal, .bottom], 24)

                    AppleAuthButton()

                    Button {
                        authRouter.push(.login)
                    } label: {
                        Text("Login")
                            .bold()
                            .foregroundStyle(.black)
                    }

                    Button {
                        authRouter.push(.emailLogin)
                    } label: {
                        Text("Use email instead")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.black.opacity(0.6))
                    }
                    .padding(.top, 4)
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
                .foregroundStyle(.black)
            HStack(spacing: 6) {
                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                    .font(.footnote.weight(.semibold))
                    .underline()
                    .foregroundStyle(.black)
                Text("and")
                    .font(.footnote)
                    .foregroundStyle(.black)
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    .font(.footnote.weight(.semibold))
                    .underline()
                    .foregroundStyle(.black)
            }
        }
        .multilineTextAlignment(.center)
    }
}

private struct AppleAuthButton: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        SignInWithAppleButton(.continue) { _ in
            authVM.errorMessage = nil
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
        .clipShape(.rect(cornerRadius: 26))
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
        let name = fullName.isEmpty ? nil : fullName

        Task {
            await authVM.appleLogin(appleId: credential.user, email: email.isEmpty ? nil : email, fullName: name)
        }
    }
}

#Preview {
    RegisterLandingView()
        .environment(AuthViewModel())
        .environment(AuthRouter())
        .environment(AppSheetManager())
}
