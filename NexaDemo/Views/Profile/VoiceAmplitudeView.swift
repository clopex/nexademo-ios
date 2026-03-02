import SwiftUI

struct VoiceAmplitudeView: View {
    let isRecording: Bool
    let level: Double

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<24, id: \.self) { index in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("BrandAccent").opacity(0.45),
                                Color("BrandAccent"),
                                Color("PremiumGradientEnd")
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 4, height: barHeight(for: index))
                    .animation(.interactiveSpring(response: 0.22, dampingFraction: 0.82), value: level)
            }
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .scaleEffect(y: isRecording ? 1 : 0.92, anchor: .center)
        .opacity(isRecording ? 1 : 0)
        .animation(.spring(response: 0.34, dampingFraction: 0.84), value: isRecording)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let voiceLevel = max(0, min(1, level))
        if voiceLevel < 0.02 {
            return 8
        }

        let center = Double(23) / 2.0
        let distance = abs(Double(index) - center) / center
        let profile = max(0.2, 1.0 - (distance * 0.8))
        let height = 8 + (voiceLevel * profile * 44)
        return CGFloat(min(56, max(8, height)))
    }
}
