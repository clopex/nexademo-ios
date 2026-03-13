import SwiftUI

struct NexaPlacesResultChipView: View {
    let result: NexaPlaceSearchResult
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.name)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(result.categoryName ?? "Nearby place")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.66))
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? Color("BrandAccent")
                    : Color("CardBackground")
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        isSelected ? Color("BrandAccent") : .white.opacity(0.08),
                        lineWidth: 1
                    )
            }
            .clipShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1 : 0.98)
        .shadow(
            color: isSelected ? Color("BrandAccent").opacity(0.28) : .black.opacity(0.12),
            radius: isSelected ? 10 : 6,
            y: isSelected ? 6 : 3
        )
        .animation(.spring(response: 0.24, dampingFraction: 0.8), value: isSelected)
    }
}
