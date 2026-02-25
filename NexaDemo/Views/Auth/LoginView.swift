import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var goToEmail = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer().frame(height: 80)

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

                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 200, weight: .regular))
                        .foregroundStyle(
                            LinearGradient(colors: [.white, Color(.systemGray4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 0)

                    Spacer()

                    VStack(spacing: 8) {
                        TermsText()
                            .padding([.horizontal, .bottom], 24)

                        AppleAuthButton()

                        NavigationLink(destination: EmailLoginView().environment(authVM), isActive: $goToEmail) {
                            EmptyView()
                        }
                        .hidden()

                        Button { goToEmail = true } label: {
                            Text("Use email instead")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.black.opacity(0.6))
                        }
                        .padding(.top, 4)
                    }
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
                .foregroundColor(.black)
            HStack(spacing: 6) {
                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                    .font(.footnote.weight(.semibold))
                    .underline()
                    .foregroundColor(.black)
                Text("and")
                    .font(.footnote)
                    .foregroundColor(.black)
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    .font(.footnote.weight(.semibold))
                    .underline()
                    .foregroundColor(.black)
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
        let name = fullName.isEmpty ? nil : fullName

        Task {
            await authVM.appleLogin(appleId: credential.user, email: email.isEmpty ? nil : email, fullName: name)
        }
    }
}

private struct EmailLoginView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isSecure = true
    @State private var showRegister = false

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 0) {
                // top spacer to mimic status bar offset
                Spacer().frame(height: 12)

                // content centered vertically
                Spacer()
                VStack(spacing: 20) {
                    Text("What is your email address?")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.black.opacity(0.85))

                    VStack(spacing: 18) {
                        underlinedField(
                            placeholder: "john.smith@gmail.com",
                            text: $email,
                            isSecure: false
                        )

                        underlinedField(
                            placeholder: "Password",
                            text: $password,
                            isSecure: isSecure,
                            showsEye: true
                        )
                    }
                }
                Spacer()

                if let error = authVM.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }

                Button {
                    Task { await authVM.login(email: email, password: password) }
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(buttonColor)
                        .cornerRadius(28)
                }
                .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showRegister) {
            RegisterView()
                .environment(authVM)
        }
    }

    private var buttonColor: Color {
        (authVM.isLoading || email.isEmpty || password.isEmpty)
        ? Color.gray.opacity(0.5)
        : Color.black
    }

    @ViewBuilder
    private func underlinedField(placeholder: String, text: Binding<String>, isSecure: Bool, showsEye: Bool = false) -> some View {
        VStack(spacing: 8) {
            HStack {
                ZStack(alignment: .leading) {
                    if text.wrappedValue.isEmpty {
                        Text(placeholder)
                            .foregroundColor(Color.gray.opacity(0.45))
                    }
                    if isSecure {
                        SecureField("", text: text)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        TextField("", text: text)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                    }
                }
                if showsEye {
                    Button {
                        self.isSecure.toggle()
                    } label: {
                        Image(systemName: isSecure ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
            }
            Rectangle()
                .fill(Color.gray.opacity(0.25))
                .frame(height: 1)
        }
        .font(.title3.weight(.semibold))
        .padding(.horizontal, 32)
    }
}

#Preview {
    LoginView()
        .environment(AuthViewModel())
}
