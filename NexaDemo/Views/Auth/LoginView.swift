import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isSecure = true
    @FocusState private var focusField: Field?

    private enum Field: Hashable {
        case email, password
    }

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 24)

                Spacer()
                VStack(spacing: 24) {
                    Text("Log in")
                        .font(.title2.bold())
                        .foregroundStyle(.black.opacity(0.85))

                    VStack(spacing: 14) {
                        underlinedField(
                            placeholder: "john.smith@gmail.com",
                            text: $email,
                            isSecure: false,
                            showsEye: false,
                            focus: .email
                        )

                        underlinedField(
                            placeholder: "Password",
                            text: $password,
                            isSecure: isSecure,
                            showsEye: true,
                            toggleSecure: { isSecure.toggle() },
                            focus: .password
                        )
                    }
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
                    Task { await authVM.login(email: email, password: password) }
                } label: {
                    Text("Continue")
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
        .task {
            if email.isEmpty { focusField = .email }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back", systemImage: "chevron.left") {
                    dismiss()
                }
                .labelStyle(.iconOnly)
            }
        }
    }

    private var isContinueDisabled: Bool {
        authVM.isLoading || !isValidEmail(email) || password.isEmpty
    }

    private var buttonColor: Color {
        isContinueDisabled ? .gray.opacity(0.5) : .black
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
                            .focused($focusField, equals: focus)
                    } else {
                        TextField("", text: text)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.center)
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
}

#Preview {
    NavigationStack {
        LoginView()
            .environment(AuthViewModel())
    }
}
