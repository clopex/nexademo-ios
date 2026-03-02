import SwiftUI

struct UsageRowView: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color

    var body: some View {
        HStack {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)

                Text(title)
                    .foregroundStyle(.white)
            }
            .font(.subheadline)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}
