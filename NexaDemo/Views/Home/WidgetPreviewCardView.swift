import SwiftUI

struct WidgetPreviewCardView: View {
    let aiScansUsageText: String
    let voiceUsageText: String
    let callsUsageText: String
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
                    value: aiScansUsageText,
                    iconColor: Color("BrandAccent")
                )

                UsageRowView(
                    icon: "mic.fill",
                    title: "Voice",
                    value: voiceUsageText,
                    iconColor: Color("BrandAccent")
                )

                UsageRowView(
                    icon: "phone.fill",
                    title: "Calls",
                    value: callsUsageText,
                    iconColor: Color("BrandAccent")
                )
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .clipShape(.rect(cornerRadius: 16))
    }

}
