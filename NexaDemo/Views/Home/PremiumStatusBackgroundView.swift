import SwiftUI

struct PremiumStatusBackgroundView: View {
    let isPremium: Bool

    var body: some View {
        if isPremium {
            LinearGradient(
                colors: [Color("PremiumGradientStart"), Color("PremiumGradientEnd")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color("CardBackground")
        }
    }
}
