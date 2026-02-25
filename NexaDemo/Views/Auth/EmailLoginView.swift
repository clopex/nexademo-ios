import SwiftUI

struct EmailLoginView: View {
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
                Spacer().frame(height: 12)

                Spacer()
                VStack(spacing: 28) {
                    Text("What is your email address?")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.black.opacity(0.85))

                    VStack(spacing: 22) {
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
        VStack(spacing: 10) {
            HStack {
                ZStack(alignment: .leading) {
                    if text.wrappedValue.isEmpty {
                        Text(placeholder)
                            .foregroundColor(Color.gray.opacity(0.4))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    if isSecure {
                        SecureField("", text: text)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.center)
                    } else {
                        TextField("", text: text)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.center)
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
            .frame(height: 48)
            Rectangle()
                .fill(Color.gray.opacity(0.25))
                .frame(height: 1)
        }
        .font(.title3.weight(.semibold))
        .padding(.horizontal, 32)
    }
}

#Preview {
    NavigationStack {
        EmailLoginView()
            .environment(AuthViewModel())
    }
}
