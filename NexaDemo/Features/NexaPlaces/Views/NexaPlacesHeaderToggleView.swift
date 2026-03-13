import SwiftUI

struct NexaPlacesHeaderToggleView: View {
    let action: () -> Void

    var body: some View {
        Button("Nexa Places", systemImage: "chevron.down.circle.fill", action: action)
            .buttonStyle(.borderedProminent)
            .tint(Color("BrandAccent"))
            .shadow(color: .black.opacity(0.18), radius: 10, y: 6)
    }
}
