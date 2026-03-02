import SwiftUI

struct VoiceNotesEmptyStateView: View {
    var body: some View {
        VStack (spacing: 12){
            Spacer()
            Image(systemName: "mic.slash")
                .font(.largeTitle)
                .foregroundStyle(Color("BrandAccent"))

            Text("No Voice Notes")
                .font(.title3)
                .bold()
                .foregroundStyle(.black)

            Text("Tap the mic button to record your first voice note")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    VoiceNotesEmptyStateView()
}
