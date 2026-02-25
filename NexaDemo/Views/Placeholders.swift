import SwiftUI

struct ForgotPasswordView: View {
    var body: some View { placeholder("Forgot Password") }
}

struct EditProfileView: View { var body: some View { placeholder("Edit Profile") } }
struct PaywallView: View { var body: some View { placeholder("Paywall") } }
struct ImagePickerView: View { var body: some View { placeholder("Image Picker") } }
struct CameraView: View { var body: some View { placeholder("Camera") } }
struct OnboardingView: View { var body: some View { placeholder("Onboarding") } }
struct AIStudioView: View { var body: some View { placeholder("AI Studio") } }
struct AIChatView: View { var body: some View { placeholder("AI Chat") } }
struct ScanResultView: View { let result: String; var body: some View { placeholder("Scan: \(result)") } }
struct PaymentView: View { var body: some View { placeholder("Payment") } }
struct TransactionHistoryView: View { var body: some View { placeholder("Transactions") } }
struct ProfileView: View { var body: some View { placeholder("Profile") } }
struct SettingsView: View { var body: some View { placeholder("Settings") } }
struct NotificationsView: View { var body: some View { placeholder("Notifications") } }

private func placeholder(_ text: String) -> some View {
    Text(text)
        .font(.title3)
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Background"))
}
