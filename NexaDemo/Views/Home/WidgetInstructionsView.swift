import SwiftUI

struct WidgetInstructionsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Add the Nexa widget")
                .font(.title3)
                .bold()
                .foregroundStyle(.primary)

            Text("Press and hold the Home Screen, tap the + button, then select Nexa to add the widget.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Background"))
    }
}
