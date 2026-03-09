import SwiftUI

struct FocusSessionCardView: View {
    let session: FocusSession
    let onEndSession: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Label(session.title, systemImage: session.preset.systemImage)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Shield active on \(session.blockedItemsCount) selections")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Text(session.endsAt, style: .timer)
                    .font(.title3)
                    .bold()
                    .foregroundStyle(Color("BrandAccent"))
                    .monospacedDigit()
            }

            Button("End Session", systemImage: "xmark.circle.fill", action: onEndSession)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color("PremiumGradientStart"))
                .clipShape(.rect(cornerRadius: 20))
                .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("CardBackground"))
        .clipShape(.rect(cornerRadius: 24))
    }
}

#Preview {
    FocusSessionCardView(
        session: FocusSession(
            title: "Study Focus",
            startedAt: .now,
            endsAt: .now.addingTimeInterval(40 * 60),
            durationMinutes: 40,
            preset: .study,
            blockedItemsCount: 3,
            shouldNotifyAtEnd: true
        ),
        onEndSession: {}
    )
    .padding()
    .background(Color("BackgroundDark"))
}
