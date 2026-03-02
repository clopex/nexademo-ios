import SwiftUI

struct RecentActivityView: View {
    private let items: [ActivityItem] = [
        ActivityItem(
            icon: "camera.viewfinder",
            colorAssetName: "BrandAccent",
            title: "Scanned MacBook Pro",
            subtitle: "98% confidence",
            time: "2 min ago"
        ),
        ActivityItem(
            icon: "bubble.left.and.bubble.right",
            colorAssetName: "PremiumGradientEnd",
            title: "AI Chat session",
            subtitle: "5 messages exchanged",
            time: "1 hour ago"
        ),
        ActivityItem(
            icon: "creditcard",
            colorAssetName: "SuccessAccent",
            title: "Upgraded to Premium",
            subtitle: "Plan activated",
            time: "Yesterday"
        ),
        ActivityItem(
            icon: "phone.fill",
            colorAssetName: "PremiumGradientStart",
            title: "Voice call with Alex",
            subtitle: "Duration: 4:32",
            time: "Yesterday"
        ),
        ActivityItem(
            icon: "mic.fill",
            colorAssetName: "PremiumGradientEnd",
            title: "Voice note saved",
            subtitle: "Duration: 0:45",
            time: "2 days ago"
        )
    ]

    var body: some View {
        VStack {
            ForEach(items) { item in
                ActivityRowView(item: item)
            }
        }
    }
}
