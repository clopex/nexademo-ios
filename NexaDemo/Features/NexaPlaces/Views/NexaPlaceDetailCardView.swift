import SwiftUI

struct NexaPlaceDetailCardView: View {
    let result: NexaPlaceSearchResult
    let isAddingToWallet: Bool
    let onRoute: () -> Void
    let onOpenInMaps: () -> Void
    let onPlanVisit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(result.name)
                .font(.headline)
                .foregroundStyle(.white)

            if let categoryName = result.categoryName {
                Text(categoryName)
                    .font(.caption)
                    .foregroundStyle(Color("BrandAccent"))
            }

            if result.address.isEmpty == false {
                Label(result.address, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.76))
            }

            if let phoneNumber = result.phoneNumber {
                Label(phoneNumber, systemImage: "phone")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.76))
            }

            HStack(spacing: 12) {
                Button("Route", systemImage: "arrow.triangle.turn.up.right.diamond.fill", action: onRoute)
                    .buttonStyle(.borderedProminent)
                    .tint(Color("BrandAccent"))

                Button("Maps", systemImage: "map", action: onOpenInMaps)
                    .buttonStyle(.bordered)
                    .tint(.white)

                Button(isAddingToWallet ? "Adding..." : "Plan", systemImage: "wallet.pass", action: onPlanVisit)
                    .buttonStyle(.bordered)
                    .tint(Color("SuccessAccent"))
                    .disabled(isAddingToWallet)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("CardBackground"))
        .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        }
        .clipShape(.rect(cornerRadius: 24))
    }
}
