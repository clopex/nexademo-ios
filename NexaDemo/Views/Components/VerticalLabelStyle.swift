import SwiftUI

struct VerticalLabelStyle: LabelStyle {
    let iconColor: Color
    let titleColor: Color

    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.icon
                .font(.title3)
                .foregroundStyle(iconColor)

            configuration.title
                .font(.caption)
                .foregroundStyle(titleColor)
        }
    }
}
