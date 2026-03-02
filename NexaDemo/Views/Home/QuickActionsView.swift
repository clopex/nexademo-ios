import SwiftUI

struct QuickActionsView: View {
    let onQuickScan: () -> Void
    let onAIChat: () -> Void
    let onCall: () -> Void
    let onVoiceNote: () -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                QuickActionCardView(
                    title: "Quick Scan",
                    systemImage: "camera.viewfinder",
                    action: onQuickScan
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
