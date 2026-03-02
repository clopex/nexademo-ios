import Foundation

struct ActivityItem: Identifiable, Sendable {
    let id = UUID()
    let icon: String
    let colorAssetName: String
    let title: String
    let subtitle: String
    let time: String
}
