import SwiftUI

struct QuickActionsView: View {
    let onAIFocus: () -> Void
    let onAIChat: () -> Void
    let onCall: () -> Void
    let onVoiceNote: () -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                QuickActionCardView(
                    title: "AI Focus",
                    systemImage: "brain.head.profile",
                    action: onAIFocus
                )

                QuickActionCardView(
                    title: "AI Chat",
                    systemImage: "sparkles",
                    action: onAIChat
                )

                QuickActionCardView(
                    title: "Call",
                    systemImage: "phone.fill",
                    action: onCall
                )

                QuickActionCardView(
                    title: "Voice Note",
                    systemImage: "mic.fill",
                    action: onVoiceNote
                )
            }
        }
        .scrollIndicators(.hidden)
    }
}
