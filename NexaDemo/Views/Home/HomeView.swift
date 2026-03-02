import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(HomeRouter.self) private var homeRouter
    @Environment(AppSheetManager.self) private var sheetManager
    @Environment(AppTabRouter.self) private var tabRouter
    @Query(sort: \VoiceNote.createdAt, order: .reverse) private var voiceNotes: [VoiceNote]

    @State private var showWidgetSheet = false

    var body: some View {
        ZStack {
            Color("BackgroundDark").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    HomeHeaderView(
                        greeting: greetingText(),
                        subtitle: "Here's your daily overview",
                        profileImageURL: authVM.currentUser?.profilePicture,
                        onNotifications: { homeRouter.push(.notifications) }
                    )

                    PremiumStatusCardView(
                        isPremium: authVM.currentUser?.isPremium ?? false,
                        onUpgrade: { sheetManager.present(.paywall) }
                    )

                    WidgetPreviewCardView(
                        isPremium: authVM.currentUser?.isPremium ?? false,
                        voiceUsageText: voiceUsageText,
                        onAddToHome: { showWidgetSheet = true }
                    )

                    SectionTitleView(title: "Quick Actions")
                    QuickActionsView(
                        onQuickScan: { sheetManager.presentFullScreen(.camera) },
                        onAIChat: { tabRouter.openAI(.chat) },
                        onCall: { tabRouter.openConnect(.contactDetail("demo")) },
                        onVoiceNote: { tabRouter.openProfile(.voiceNotes) }
                    )

                    SectionTitleView(title: "Recent Activity")
                    RecentActivityView()

                    SectionTitleView(title: "AI Tip of the Day")
                    AITipCardView()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showWidgetSheet) {
            WidgetInstructionsView()
        }
    }

    private func greetingText() -> String {
        let rawName = authVM.currentUser?.fullName ?? ""
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstName = name.split(separator: " ").first.map(String.init) ?? "there"
        return "\(greetingPrefix(for: Date())), \(capitalizeFirstLetter(firstName))"
    }

    private func greetingPrefix(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 0..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }

    private func capitalizeFirstLetter(_ value: String) -> String {
        guard let first = value.first else { return value }
        return first.uppercased() + value.dropFirst()
    }

    private var voiceUsageText: String {
        let count = voiceNotes.count
        let totalDuration = VoiceNoteDurationStore.totalDuration(for: voiceNotes)
        return "\(count) notes • \(formattedDuration(totalDuration))"
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let clamped = max(0, Int(seconds.rounded()))
        let minutes = clamped / 60
        let remainingSeconds = clamped % 60
        let paddedSeconds = remainingSeconds < 10 ? "0\(remainingSeconds)" : "\(remainingSeconds)"
        return "\(minutes):\(paddedSeconds)"
    }
}
