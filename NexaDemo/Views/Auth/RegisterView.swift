import SwiftUI

struct RegisterView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showToast = false
    @State private var toast = Toast.example

    var body: some View {
        ZStack {
            Color("BackgroundDark").ignoresSafeArea()

            VStack(spacing: 28) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                            .padding()
                    }
                    Spacer()
                }

                Text("Kreiraj račun")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                VStack(spacing: 14) {
                    AuthTextField(
                        placeholder: "Ime i prezime",
                        text: $fullName,
                        icon: "person",
                        isSecure: false,
                        keyboardType: .default,
                        autocapitalization: .words
                    )

                    AuthTextField(
                        placeholder: "Email",
                        text: $email,
                        icon: "envelope",
                        isSecure: false,
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )

                    AuthTextField(
                        placeholder: "Password (min 6 znakova)",
                        text: $password,
                        icon: "lock",
                        isSecure: true
                    )
                }

                Button {
                    Task { await authVM.register(fullName: fullName, email: email, password: password) }
                } label: {
                    if authVM.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Registriraj se")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                    }
                }
                .background(Color("BrandAccent"))
                .clipShape(.rect(cornerRadius: 14))
                .disabled(authVM.isLoading || fullName.isEmpty || email.isEmpty || password.isEmpty)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .dynamicIslandToasts(isPresented: $showToast, value: toast)
        .onChange(of: authVM.errorMessage) { _, newValue in
            guard let message = newValue, !message.isEmpty else { return }
            toast = Toast(
                symbol: "xmark.seal.fill",
                symbolFont: .system(size: 28),
                symbolForegrgoundStyle: (.white, .red),
                title: "Registration failed",
                message: message
            )
            showToast = true
        }
        .onChange(of: fullName) { _, _ in dismissToast() }
        .onChange(of: email) { _, _ in dismissToast() }
        .onChange(of: password) { _, _ in dismissToast() }
    }

    private func dismissToast() {
        if showToast {
            showToast = false
        }
        authVM.errorMessage = nil
    }
}
