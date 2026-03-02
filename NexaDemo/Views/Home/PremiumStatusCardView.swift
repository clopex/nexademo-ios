import SwiftUI

struct PremiumStatusCardView: View {
    let isPremium: Bool
    let onUpgrade: () -> Void

    var body: some View {
        HStack {
            if isPremium {
                HStack(spacing: 8) {
                    Text("Premium Active")
                        .font(.headline)
                        .bold()

                    Image(systemName: "checkmark.seal.fill")
                }
                .foregroundStyle(Color("SuccessAccent"))
            } else {
                VStack(alignment: .leading) {
                    Text("Free Plan")
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.white)

                    Text("Unlock all features")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Button("Upgrade", action: onUpgrade)
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color("BrandAccent"))
                    .clipShape(.capsule)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(PremiumStatusBackgroundView(isPremium: isPremium))
        .clipShape(.rect(cornerRadius: 16))
    }
}
