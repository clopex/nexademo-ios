import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("NexaDemo")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    Text("Dobrodošao nazad")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 60)

                VStack(spacing: 16) {
                    AuthTextField(
                        placeholder: "Email",
                        text: $email,
                        icon: "envelope",
                        isSecure: false,
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )

                    AuthTextField(
                        placeholder: "Password",
                        text: $password,
                        icon: "lock",
                        isSecure: true
                    )
                }

                if let error = authVM.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await authVM.login(email: email, password: password) }
                } label: {
                    if authVM.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Prijavi se")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                    }
                }
                .background(Color(hex: "E94560"))
                .cornerRadius(14)
                .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)

                Button { showRegister = true } label: {
                    Text("Nemaš račun? Registriraj se")
                        .foregroundColor(Color(hex: "0F3460"))
                        .font(.subheadline)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
                .environment(authVM)
        }
    }
}
