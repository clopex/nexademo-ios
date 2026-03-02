import SwiftUI

struct ActivityRowView: View {
    let item: ActivityItem

    var body: some View {
        HStack {
            Color(item.colorAssetName)
                .opacity(0.15)
                .frame(width: 40, height: 40)
                .clipShape(.rect(cornerRadius: 12))
                .overlay {
                    Image(systemName: item.icon)
                        .foregroundStyle(Color(item.colorAssetName))
                }

            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.white)

                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Text(item.time)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}
