import AlarmKit
import Foundation

struct VoiceNoteAlarmMetadata: AlarmMetadata {
    let reminderID: UUID
    let title: String
    let createdAt: Date

    init(reminderID: UUID, title: String, createdAt: Date = .now) {
        self.reminderID = reminderID
        self.title = title
        self.createdAt = createdAt
    }
}
