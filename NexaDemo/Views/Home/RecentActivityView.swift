import SwiftUI

struct RecentActivityView: View {
    let items: [ActivityItem]

    var body: some View {
        VStack {
            ForEach(items) { item in
                ActivityRowView(item: item)
            }
        }
    }
}

#Preview {
    RecentActivityView(
        items: [
            ActivityItem(
                icon: "mic.fill",
                colorAssetName: "PremiumGradientEnd",
                title: "Voice note saved",
                subtitle: "Duration: 0:45",
                time: "Now"
            )
        ]
    )
    .padding()
    .background(Color("BackgroundDark"))
}
