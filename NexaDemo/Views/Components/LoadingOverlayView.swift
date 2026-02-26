import SwiftUI

struct LoadingOverlayView: View {
    let messages: [String]
    @State private var spin = false
    @State private var pulse = false

    init(messages: [String] = LoadingOverlayView.defaultMessages) {
        self.messages = messages
    }

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                LoadingMessageCarousel(messages: messages)
                SpinnerOrbital(spin: spin, pulse: pulse)
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

    private static let defaultMessages = [
        "Warming up the servers...",
        "Polishing the pixels...",
        "Asking the cloud nicely...",
        "Still faster than a coffee run...",
        "Almost there..."
    ]
}

private struct LoadingMessageCarousel: View {
    let messages: [String]
    @State private var index = 0
    @State private var opacity = 0.0
    @State private var offset: CGFloat = 30
    @State private var started = false

    var body: some View {
        Text(messages[index])
            .font(.footnote)
            .bold()
            .foregroundStyle(.black.opacity(0.75))
            .opacity(opacity)
            .offset(y: offset)
            .task {
                guard !started else { return }
                started = true
                await runLoop()
            }
    }

    private func runLoop() async {
        while !Task.isCancelled {
            await animateIn()
            try? await Task.sleep(for: .seconds(1))
            await animateOut()
            try? await Task.sleep(for: .seconds(0.2))
            index = (index + 1) % messages.count
        }
    }

    @MainActor
    private func animateIn() {
        withAnimation(.easeOut(duration: 0.35)) {
            opacity = 1
            offset = 0
        }
    }

    @MainActor
    private func animateOut() {
        withAnimation(.easeIn(duration: 0.25)) {
            opacity = 0
            offset = -30
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
    LoadingOverlayView()
}
