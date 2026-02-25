import SwiftUI

struct RegisterView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

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

                if let error = authVM.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
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
                .background(Color(hex: "E94560"))
                .clipShape(.rect(cornerRadius: 14))
                .disabled(authVM.isLoading || fullName.isEmpty || email.isEmpty || password.isEmpty)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}
