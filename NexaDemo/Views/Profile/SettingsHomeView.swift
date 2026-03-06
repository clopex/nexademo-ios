import SwiftUI
import LocalAuthentication

struct SettingsHomeView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(ProfileRouter.self) private var router

    var body: some View {
        ZStack {
            Color("BackgroundDark").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // Account section
                    SettingsSection(title: "Account") {
                        SettingsRow(
                            title: "Profile",
                            subtitle: "Edit your personal information",
                            icon: "person.crop.circle",
                            iconBackground: Color("PremiumGradientStart")
                        ) {
                            router.push(.profile)
                        }

                        Divider()
                            .background(Color.white.opacity(0.05))
                            .padding(.leading, 56)

                        SettingsRow(
                            title: "Biometric Login",
                            subtitle: "Face ID / Touch ID",
                            icon: "faceid",
                            iconBackground: Color("PremiumGradientEnd")
                        ) {
                            router.push(.biometricSetup)
                        }
                    }

                    // App section
                    SettingsSection(title: "App") {
                        SettingsRow(
                            title: "Voice Notes",
                            subtitle: "Manage your recordings",
                            icon: "mic.fill",
                            iconBackground: Color("BrandAccent")
                        ) {
                            router.push(.voiceNotes)
                        }
                    }

                    // Danger zone
                    SettingsSection(title: "Account Actions") {
                        Button {
                            authVM.logout()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.red)
                                }
                                Text("Logout")
                                    .font(.body)
                                    .foregroundStyle(.red)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.gray)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .background(Color("CardBackground"))
            .clipShape(.rect(cornerRadius: 16))
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconBackground: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconBackground)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Biometric Setup View
struct BiometricSetupView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var isEnabled = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var biometricType: LABiometryType = .none

    private let context = LAContext()

    var biometricName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "Biometric"
        }
    }

    var biometricIcon: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.fill"
        }
    }

    var body: some View {
        ZStack {
            Color("BackgroundDark").ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color("PremiumGradientStart"), Color("PremiumGradientEnd")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                    Image(systemName: biometricIcon)
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 12) {
                    Text(biometricType == .none ? "Biometric Not Available" : "\(biometricName) Login")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    Text(biometricType == .none
                         ? "Your device doesn't support biometric authentication."
                         : "Use \(biometricName) to log in quickly without typing your password.")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Status card
                if biometricType != .none {
                    HStack(spacing: 16) {
                        Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(isEnabled ? Color("SuccessAccent") : .gray)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(isEnabled ? "\(biometricName) Enabled" : "\(biometricName) Disabled")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                            Text(isEnabled ? "You can now login with \(biometricName)" : "Tap below to enable")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }

                        Spacer()

                        Toggle("", isOn: $isEnabled)
                            .tint(Color("BrandAccent"))
                            .onChange(of: isEnabled) { _, newValue in
                                if newValue {
                                    Task { await enableBiometric() }
                                } else {
                                    disableBiometric()
                                }
                            }
                    }
                    .padding(16)
                    .background(Color("CardBackground"))
                    .clipShape(.rect(cornerRadius: 16))
                    .padding(.horizontal, 20)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                if showSuccess {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color("SuccessAccent"))
                        Text("\(biometricName) successfully enabled!")
                            .font(.subheadline)
                            .foregroundStyle(Color("SuccessAccent"))
                    }
                }

                Spacer()
            }
        }
        .navigationTitle("Biometric Login")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkBiometricAvailability()
            isEnabled = BiometricAuthService.isEnabled()
        }
    }

    // MARK: - Biometric Logic
    private func checkBiometricAvailability() {
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        }
    }

    private func enableBiometric() async {
        isLoading = true
        errorMessage = nil

        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            errorMessage = error?.localizedDescription ?? "Biometric not available"
            isEnabled = false
            isLoading = false
            return
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to enable \(biometricName) login"
            )

            if success {
                if let email = authVM.currentUser?.email {
                    BiometricAuthService.enable(email: email)
                    await authVM.refreshBiometricLoginAvailability()
                    showSuccess = true
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        showSuccess = false
                    }
                }
            } else {
                isEnabled = false
            }
        } catch {
            errorMessage = error.localizedDescription
            isEnabled = false
        }

        isLoading = false
    }

    private func disableBiometric() {
        BiometricAuthService.disable()
        Task {
            await authVM.refreshBiometricLoginAvailability()
        }
    }
}

#Preview {
    NavigationStack {
        BiometricSetupView()
            .environment(AuthViewModel())
    }
}
