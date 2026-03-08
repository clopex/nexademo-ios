import ActivityKit
import Foundation

struct ReminderAlarmAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var title: String
        var scheduledAt: Date
        var remainingSeconds: Int
        var label: String
    }

    var reminderID: UUID
}
