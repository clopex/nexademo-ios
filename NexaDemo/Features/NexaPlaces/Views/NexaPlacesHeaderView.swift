import SwiftUI

struct NexaPlacesHeaderView: View {
    let onClose: () -> Void
    let statusMessage: String
    let hasError: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI-powered location assistant")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Use the Nexa assistant button for voice place searches.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.76))
                }

                Spacer()

                Button("Close", systemImage: "xmark", action: onClose)
                    .buttonStyle(.bordered)
                    .tint(.white)
            }

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    NexaPlacesPillView(title: "Apple Maps", systemImage: "map")
                    NexaPlacesPillView(title: "CoreLocation", systemImage: "location.fill")
                    NexaPlacesPillView(title: "Nexa Assistant", systemImage: "sparkles")
                    NexaPlacesPillView(title: "MKLocalSearch", systemImage: "sparkles")
                }
            }
            .scrollIndicators(.hidden)

            Text(statusMessage)
                .font(.caption)
                .foregroundStyle(hasError ? .red.opacity(0.92) : .white.opacity(0.76))
                .lineLimit(2)
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    Color("BackgroundDark").opacity(0.96),
                    Color("CardBackground").opacity(0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color("BrandAccent").opacity(0.2), lineWidth: 1)
        }
        .clipShape(.rect(cornerRadius: 24))
    }
}
