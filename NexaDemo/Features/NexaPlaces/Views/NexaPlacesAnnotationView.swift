import SwiftUI

struct NexaPlacesAnnotationView: View {
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundStyle(isSelected ? Color("BrandAccent") : Color("SuccessAccent"))

            Circle()
                .fill(.white)
                .frame(width: 8, height: 8)
        }
    }
}
