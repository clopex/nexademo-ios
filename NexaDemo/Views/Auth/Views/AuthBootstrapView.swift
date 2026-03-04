import SwiftUI

struct AuthBootstrapView: View {
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack {
                ProgressView()
                    .tint(.black)
                Text("Checking session...")
                    .font(.subheadline)
                    .foregroundStyle(.black.opacity(0.6))
            }
        }
    }
}

#Preview {
    AuthBootstrapView()
}
