import SwiftUI

struct HomeHeaderView: View {
    let greeting: String
    let subtitle: String
    let profileImageURL: String?
    let onNotifications: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                ProfileAvatarView(imageURL: profileImageURL, size: 50)

                Spacer()

                Button("Notifications", systemImage: "bell", action: onNotifications)
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.white)
                    .font(.title3)
                    .buttonStyle(.plain)
            }

            VStack(alignment: .leading) {
                Text(greeting)
                    .font(.title3)
                    .bold()
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}

private struct ProfileAvatarView: View {
    let imageURL: String?
    let size: CGFloat

    var body: some View {
        ZStack {
            Color.white.opacity(0.08)
                .clipShape(.circle)

            if let imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "person.crop.circle")
                            .foregroundStyle(.white.opacity(0.7))
                    case .empty:
                        ProgressView()
                            .tint(.white.opacity(0.7))
                    @unknown default:
                        Image(systemName: "person.crop.circle")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .clipShape(.circle)
            } else {
                Image(systemName: "person.crop.circle")
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
    }
}
