import SwiftUI

struct VoiceNotesFloatingButton: View {
    let action: () -> Void

    var body: some View {
        Button("Record", systemImage: "mic.fill", action: action)
            .labelStyle(.iconOnly)
            .font(.title2)
            .foregroundStyle(.white)
            .frame(width: 64, height: 64)
            .background(Color("BrandAccent"))
            .clipShape(.circle)
            .shadow(color: Color("BrandAccent").opacity(0.4), radius: 12, x: 0, y: 6)
    }
}
