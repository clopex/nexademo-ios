import SwiftUI

struct QuickActionCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .shadow(
                color: .black.opacity(configuration.isPressed ? 0.12 : 0.22),
                radius: configuration.isPressed ? 6 : 12,
                y: configuration.isPressed ? 4 : 8
            )
            .animation(.spring(response: 0.22, dampingFraction: 0.74), value: configuration.isPressed)
    }
}
