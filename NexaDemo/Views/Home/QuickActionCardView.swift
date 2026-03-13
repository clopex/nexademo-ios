import SwiftUI

struct QuickActionCardView: View {
    let title: String
    let systemImage: String
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(accentColor)
                    .frame(height: 22)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 104)
            .frame(minHeight: 92)
            .background(
                LinearGradient(
                    colors: [
                        Color("CardBackground"),
                        accentColor.opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            }
            .clipShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(QuickActionCardButtonStyle())
    }
}
