import SwiftUI

struct LoadingOverlayView: View {
    let text: String
    @State private var spin = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                SpinnerOrbital(spin: spin, pulse: pulse)
                Text(text)
                    .font(.footnote.bold())
                    .foregroundStyle(.black.opacity(0.75))
            }
            .padding(20)
            .background(Color.white)
            .clipShape(.rect(cornerRadius: 20))
            .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
        }
        .task {
            spin = true
            pulse = true
        }
    }
}

private struct SpinnerOrbital: View {
    let spin: Bool
    let pulse: Bool

    var body: some View {
        Circle()
            .trim(from: 0.12, to: 0.88)
            .stroke(
                AngularGradient(
                    colors: [.black.opacity(0.12), .black.opacity(0.55), .black.opacity(0.12)],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
            .rotationEffect(.degrees(spin ? 360 : 0))
            .animation(
                .linear(duration: 1.1).repeatForever(autoreverses: false),
                value: spin
            )
            .frame(width: 48, height: 48)
            .scaleEffect(pulse ? 1.0 : 0.94)
            .animation(
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                value: pulse
            )
    }
}

#Preview {
    LoadingOverlayView(text: "Signing in...")
}
