import SwiftUI

struct QuickActionsView: View {
    let onAIFocus: () -> Void
    let onAIChat: () -> Void
    let onNexaPlaces: () -> Void
    let onCall: () -> Void
    let onVoiceNote: () -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                QuickActionCardView(
                    title: "AI Focus",
                    systemImage: "brain.head.profile",
                    accentColor: Color("BrandAccent"),
                    action: onAIFocus
                )

                QuickActionCardView(
                    title: "AI Chat",
                    systemImage: "sparkles",
                    accentColor: Color("PremiumGradientEnd"),
                    action: onAIChat
                )

                QuickActionCardView(
                    title: "Nexa Places",
                    systemImage: "map.fill",
                    accentColor: Color("SuccessAccent"),
                    action: onNexaPlaces
                )

                QuickActionCardView(
                    title: "Call",
                    systemImage: "phone.fill",
                    accentColor: Color("BrandAccent"),
                    action: onCall
                )

                QuickActionCardView(
                    title: "Voice Note",
                    systemImage: "mic.fill",
                    accentColor: Color("PremiumGradientStart"),
                    action: onVoiceNote
                )
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }
}
