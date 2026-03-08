import Foundation
import SwiftData

@Model
final class VoiceNoteReminder {
    var id: UUID
    var voiceNoteID: UUID
    var systemAlarmID: UUID?
    var title: String
    var scheduledAt: Date
    var isEnabled: Bool
    var liveActivityID: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        voiceNoteID: UUID,
        systemAlarmID: UUID? = nil,
        title: String,
        scheduledAt: Date,
        isEnabled: Bool = true,
        liveActivityID: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.voiceNoteID = voiceNoteID
        self.systemAlarmID = systemAlarmID
        self.title = title
        self.scheduledAt = scheduledAt
        self.isEnabled = isEnabled
        self.liveActivityID = liveActivityID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
