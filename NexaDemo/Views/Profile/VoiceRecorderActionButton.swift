import SwiftUI

struct VoiceRecorderActionButton: View {
    let isRecording: Bool
    let action: () -> Void
    @State private var tapTrigger = 0

    var body: some View {
        Button {
            tapTrigger += 1
            action()
        } label: {
            ZStack {
                if isRecording {
                    Circle()
                        .fill(Color("BrandAccent").opacity(0.25))
                        .frame(width: 100, height: 100)
                        .scaleEffect(1.18)
                        .animation(.easeInOut(duration: 0.8).repeatForever(), value: isRecording)
                }

                Circle()
                    .fill(Color(isRecording ? "BrandAccent" : "CardBackground"))
                    .frame(width: 80, height: 80)

                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: tapTrigger)
            }
            .frame(width: 100, height: 100)
        }
        .buttonStyle(VoiceRecorderPressButtonStyle())
        .contentShape(.circle)
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
    }
}

private struct VoiceRecorderPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.955 : 1)
            .opacity(configuration.isPressed ? 0.93 : 1)
            .animation(
                .interactiveSpring(response: 0.34, dampingFraction: 0.86, blendDuration: 0.12),
                value: configuration.isPressed
            )
    }
}
