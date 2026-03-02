import SwiftUI

struct WidgetPreviewCardView: View {
    let isPremium: Bool
    let onAddToHome: () -> Void

    var body: some View {
        VStack {
            HStack {
                Text("Today's Usage")
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.white)

                Spacer()

                Button("Add to Home Screen", action: onAddToHome)
                    .font(.caption)
                    .foregroundStyle(Color("BrandAccent"))
                    .buttonStyle(.plain)
            }

            VStack {
                UsageRowView(
                    icon: "camera.viewfinder",
                    title: "AI Scans",
                    value: usageValue(freeValue: "3 / 5"),
                    iconColor: Color("BrandAccent")
                )

                UsageRowView(
                    icon: "mic.fill",
                    title: "Voice",
                    value: usageValue(freeValue: "0:45 / 1:00"),
                    iconColor: Color("BrandAccent")
                )

                UsageRowView(
                    icon: "phone.fill",
                    title: "Calls",
                    value: usageValue(freeValue: "0 / ∞"),
                    iconColor: Color("BrandAccent")
                )
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .clipShape(.rect(cornerRadius: 16))
    }

    private func usageValue(freeValue: String) -> String {
        isPremium ? "∞" : freeValue
    }
}
