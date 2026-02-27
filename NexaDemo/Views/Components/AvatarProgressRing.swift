import SwiftUI

struct AvatarProgressRing: View {
    let isAnimating: Bool
    @State private var spin = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.25)
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .rotationEffect(.degrees(spin ? 360 : 0))
            .animation(
                .linear(duration: 1.0).repeatForever(autoreverses: false),
                value: spin
            )
            .onChange(of: isAnimating) { _, newValue in
                spin = newValue
            }
            .onAppear {
                spin = isAnimating
            }
    }
}
