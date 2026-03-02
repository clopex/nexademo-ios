import SwiftUI

struct QuickActionCardView: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(title, systemImage: systemImage, action: action)
            .labelStyle(VerticalLabelStyle(
                iconColor: Color("BrandAccent"),
                titleColor: .white
            ))
            .frame(width: 80, height: 80)
            .background(Color("CardBackground"))
            .clipShape(.rect(cornerRadius: 16))
            .buttonStyle(.plain)
    }
}
