import SwiftUI

struct EmailLoginView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss
    
    private enum Stage {
        case email, password, confirm
    }
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSecure = true
    @State private var isSecureConfirm = true
    @State private var showRegister = false
    @State private var stage: Stage = .email

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 12)

                Spacer()
                VStack(spacing: 24) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.black.opacity(0.85))

                    ZStack {
                        underlinedField(
                            placeholder: "john.smith@gmail.com",
                            text: $email,
                            isSecure: false,
                            showsEye: false
                        )
                        .opacity(stage == .email ? 1 : 0)
                        .offset(x: offset(for: .email))

                        underlinedField(
                            placeholder: "Password",
                            text: $password,
                            isSecure: isSecure,
                            showsEye: true,
                            toggleSecure: { isSecure.toggle() }
                        )
                        .opacity(stage == .password ? 1 : 0)
                        .offset(x: offset(for: .password))

                        underlinedField(
                            placeholder: "Repeat password",
                            text: $confirmPassword,
                            isSecure: isSecureConfirm,
                            showsEye: true,
                            toggleSecure: { isSecureConfirm.toggle() }
                        )
                        .opacity(stage == .confirm ? 1 : 0)
                        .offset(x: offset(for: .confirm))
                    }
                    .animation(.easeInOut(duration: 0.25), value: stage)
                }
                Spacer()

                if let error = authVM.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }

                Button {
                    advance()
                } label: {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(buttonColor)
                        .clipShape(.rect(cornerRadius: 28))
                }
                .disabled(isContinueDisabled)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 24, height: 24)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showRegister) {
            RegisterView()
                .environment(authVM)
        }
    }

    private var title: String {
        switch stage {
        case .email: return "What is your email address?"
        case .password: return "Enter your password"
        case .confirm: return "Repeat your password"
        }
    }

    private var buttonColor: Color {
        isContinueDisabled ? Color.gray.opacity(0.5) : Color.black
    }

    private var buttonTitle: String {
        switch stage {
        case .email, .password:
            return "Continue"
        case .confirm:
            return "Register"
        }
    }

    private var isContinueDisabled: Bool {
        switch stage {
        case .email:
            return authVM.isLoading || !isValidEmail(email)
        case .password:
            return authVM.isLoading || password.isEmpty
        case .confirm:
            return authVM.isLoading || confirmPassword.isEmpty || confirmPassword != password
        }
    }

    @ViewBuilder
    private func underlinedField(
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool,
        showsEye: Bool = false,
        toggleSecure: (() -> Void)? = nil
    ) -> some View {
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
                if showsEye, let toggleSecure {
                    Button(action: toggleSecure) {
                        Image(systemName: isSecure ? "eye.slash" : "eye")
                            .foregroundStyle(.gray)
                    }
                }
            }
            .frame(height: 40)
            Rectangle()
                .fill(Color.gray.opacity(0.25))
                .frame(height: 1)
        }
        .font(.title3.weight(.semibold))
        .padding(.horizontal, 32)
    }

    private func offset(for target: Stage) -> CGFloat {
        switch (stage, target) {
        case (.email, .email): return 0
        case (.email, _): return 120
        case (.password, .password): return 0
        case (.password, .email): return -120
        case (.password, .confirm): return 120
        case (.confirm, .confirm): return 0
        case (.confirm, .password): return -120
        default: return 120
        }
    }

    private func advance() {
        switch stage {
        case .email:
            withAnimation(.easeInOut(duration: 0.25)) { stage = .password }
        case .password:
            withAnimation(.easeInOut(duration: 0.25)) { stage = .confirm }
        case .confirm:
            Task { await authVM.login(email: email, password: password) }
        }
    }

    private func goBack() {
        switch stage {
        case .email:
            dismiss()
        case .password:
            withAnimation(.easeInOut(duration: 0.25)) { stage = .email }
        case .confirm:
            withAnimation(.easeInOut(duration: 0.25)) {
                confirmPassword = ""
                stage = .password
            }
        }
    }

    private func isValidEmail(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES[c] %@", pattern).evaluate(with: trimmed)
    }
}

#Preview {
    NavigationStack {
        EmailLoginView()
            .environment(AuthViewModel())
    }
}
