import ActivityKit
import Foundation

struct FocusSessionActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var title: String
        var endsAt: Date
        var blockedItemsCount: Int
        var label: String
    }

    var sessionID: UUID
}
