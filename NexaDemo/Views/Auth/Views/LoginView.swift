import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isSecure = true
    @State private var stage: Stage = .email
    @State private var showToast = false
    @State private var toast = Toast.example
    @FocusState private var focusField: Field?

    private enum Stage {
        case email
        case password
    }

    private enum Field: Hashable {
        case email
        case password
    }

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 24)

                Spacer()
                VStack(spacing: 24) {
                    Text("Login")
                        .font(.title2.bold())
                        .foregroundStyle(.black.opacity(0.85))

                    ZStack {
                        underlinedField(
                            placeholder: "john.smith@gmail.com",
                            text: $email,
                            isSecure: false,
                            showsEye: false,
                            focus: .email
                        )
                        .opacity(stage == .email ? 1 : 0)
                        .offset(x: stage == .email ? 0 : -120)

                        underlinedField(
                            placeholder: "Password",
                            text: $password,
                            isSecure: isSecure,
                            showsEye: true,
                            toggleSecure: { isSecure.toggle() },
                            focus: .password
                        )
                        .opacity(stage == .password ? 1 : 0)
                        .offset(x: stage == .password ? 0 : 120)
                    }
                    .animation(.easeInOut(duration: 0.25), value: stage)
                }
                Spacer()

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
            .opacity(authVM.isLoading ? 0 : 1)
            .accessibilityHidden(authVM.isLoading)

            if authVM.isLoading {
                LoadingOverlayView()
                    .allowsHitTesting(true)
            }
        }
        .toolbar(authVM.isLoading ? .hidden : .visible, for: .navigationBar)
        .task {
            if email.isEmpty { focusField = .email }
        }
        .task(id: stage) {
            switch stage {
            case .email:
                focusField = email.isEmpty ? .email : nil
            case .password:
                focusField = password.isEmpty ? .password : nil
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 24, height: 24)
                        .padding(12)
                        .background(Color.white)
                        .clipShape(.circle)
                }
                .buttonStyle(.plain)
                .disabled(authVM.isLoading)
            }
        }
        .navigationBarBackButtonHidden(true)
        .dynamicIslandToasts(isPresented: $showToast, value: toast)
        .onChange(of: authVM.errorMessage) { _, newValue in
            guard let message = newValue, !message.isEmpty else { return }
            toast = Toast(
                symbol: "xmark.seal.fill",
                symbolFont: .system(size: 28),
                symbolForegrgoundStyle: (.white, .red),
                title: "Login failed",
                message: message
            )
            showToast = true
        }
        .onChange(of: email) { _, _ in dismissToast() }
        .onChange(of: password) { _, _ in dismissToast() }
    }

    private var buttonTitle: String {
        stage == .password ? "Login" : "Continue"
    }

    private var isContinueDisabled: Bool {
        switch stage {
        case .email:
            return authVM.isLoading || !isValidEmail(email)
        case .password:
            return authVM.isLoading || password.isEmpty || !isValidEmail(email)
        }
    }

    private var buttonColor: Color {
        isContinueDisabled ? .gray.opacity(0.5) : .black
    }

    private func advance() {
        switch stage {
        case .email:
            withAnimation(.easeInOut(duration: 0.25)) { stage = .password }
        case .password:
            focusField = nil
            Task { await authVM.login(email: email, password: password) }
        }
    }

    private func goBack() {
        switch stage {
        case .email:
            dismiss()
        case .password:
            focusField = nil
            withAnimation(.easeInOut(duration: 0.25)) { stage = .email }
        }
    }

    @ViewBuilder
    private func underlinedField(
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool,
        showsEye: Bool = false,
        toggleSecure: (() -> Void)? = nil,
        focus: Field
    ) -> some View {
        VStack(spacing: 10) {
            HStack {
                ZStack(alignment: .leading) {
                    if text.wrappedValue.isEmpty {
                        Text(placeholder)
                            .foregroundStyle(.gray.opacity(0.4))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    if isSecure {
                        SecureField("", text: text)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.black)
                            .tint(.black)
                            .focused($focusField, equals: focus)
                    } else {
                        TextField("", text: text)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.black)
                            .tint(.black)
                            .focused($focusField, equals: focus)
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
        .font(.title3.bold())
        .padding(.horizontal, 32)
    }

    private func isValidEmail(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES[c] %@", pattern).evaluate(with: trimmed)
    }

    private func dismissToast() {
        if showToast {
            showToast = false
        }
        authVM.errorMessage = nil
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environment(AuthViewModel())
    }
}
