import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(HomeRouter.self) private var homeRouter
    @Environment(AppSheetManager.self) private var sheetManager
    @Environment(AppTabRouter.self) private var tabRouter
    @Environment(FocusSessionStore.self) private var focusSessionStore
    @Query(sort: \VoiceNote.createdAt, order: .reverse) private var voiceNotes: [VoiceNote]
    @Query(sort: \VoiceNoteReminder.createdAt, order: .reverse) private var voiceNoteReminders: [VoiceNoteReminder]

    @State private var showWidgetSheet = false
    @State private var aiScansToday = 0
    @State private var recentActivityVersion = 0

    var body: some View {
        let _ = recentActivityVersion
        let recentActivityItems = RecentActivityService().makeItems(
            voiceNotes: voiceNotes,
            reminders: voiceNoteReminders,
            activeFocusSession: focusSessionStore.activeSession,
            userID: authVM.currentUser?.id
        )

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
                        onUpgrade: { tabRouter.selectedTab = .premium }
                    )

                    if let session = focusSessionStore.activeSession {
                        FocusSessionCardView(session: session) {
                            Task { await focusSessionStore.endSession() }
                        }
                    }

                    WidgetPreviewCardView(
                        aiScansUsageText: aiScansUsageText,
                        voiceUsageText: voiceUsageText,
                        callsUsageText: callsUsageText,
                        onAddToHome: { showWidgetSheet = true }
                    )

                    SectionTitleView(title: "Quick Actions")
                    QuickActionsView(
                        onAIFocus: {
                            guard authVM.currentUser?.isPremium ?? false else {
                                tabRouter.selectedTab = .premium
                                return
                            }
                            homeRouter.push(
                                .focusSession(FocusAIParserService().defaultProposal())
                            )
                        },
                        onAIChat: { homeRouter.push(.aiChat) },
                        onNexaPlaces: { homeRouter.push(.nexaPlaces(query: nil)) },
                        onCall: { tabRouter.openConnect(.contactDetail("demo")) },
                        onVoiceNote: { tabRouter.openProfile(.voiceNotes) }
                    )

                    if recentActivityItems.isEmpty == false {
                        SectionTitleView(title: "Recent Activity")
                        RecentActivityView(items: recentActivityItems)
                    }

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
        .onAppear {
            refreshUsageState()
            syncWidgetUsage()
        }
        .onChange(of: voiceNotes.count) { _, _ in
            syncWidgetUsage()
        }
        .onChange(of: authVM.currentUser?.isPremium) { _, _ in
            refreshUsageState()
            syncWidgetUsage()
        }
        .onChange(of: authVM.currentUser?.fullName) { _, _ in
            syncWidgetUsage()
        }
        .onReceive(NotificationCenter.default.publisher(for: .recentActivityDidChange)) { _ in
            recentActivityVersion += 1
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

    private var aiScansUsageText: String {
        let isPremium = authVM.currentUser?.isPremium ?? false
        return isPremium ? "\(aiScansToday) / ∞" : "\(aiScansToday) / 5"
    }

    private var callsUsageText: String {
        "0 / ∞"
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let clamped = max(0, Int(seconds.rounded()))
        let minutes = clamped / 60
        let remainingSeconds = clamped % 60
        let paddedSeconds = remainingSeconds < 10 ? "0\(remainingSeconds)" : "\(remainingSeconds)"
        return "\(minutes):\(paddedSeconds)"
    }

    private func refreshUsageState() {
        aiScansToday = AIScanAttemptStore.shared.todayCount()
    }

    private func syncWidgetUsage() {
        let totalVoiceSeconds = Int(VoiceNoteDurationStore.totalDuration(for: voiceNotes).rounded())
        let isPremium = authVM.currentUser?.isPremium ?? false
        let userName = authVM.currentUser?.fullName ?? ""
        let scansToday = AIScanAttemptStore.shared.todayCount()
        aiScansToday = scansToday

        WidgetDataService.shared.syncUsage(
            isPremium: isPremium,
            userName: userName,
            voiceNotesCount: voiceNotes.count,
            voiceSecondsToday: totalVoiceSeconds,
            aiScansToday: scansToday
        )
    }
}
