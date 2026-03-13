import SwiftUI

struct NexaPlacesMapControlsView: View {
    let onResetTap: () -> Void
    let onRecenterTap: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: onResetTap) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color("BrandAccent"))
                    .clipShape(.circle)
                    .shadow(color: Color("BrandAccent").opacity(0.28), radius: 10, y: 6)
            }
            .buttonStyle(.plain)

            Button(action: onRecenterTap) {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(
                            colors: [
                                Color("BackgroundDark").opacity(0.94),
                                Color("CardBackground").opacity(0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Circle()
                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                    }
                    .clipShape(.circle)
                    .shadow(color: .black.opacity(0.18), radius: 10, y: 6)
            }
            .buttonStyle(.plain)
        }
    }
}
