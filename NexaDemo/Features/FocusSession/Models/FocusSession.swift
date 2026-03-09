import Foundation

struct FocusSession: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    var title: String
    var startedAt: Date
    var endsAt: Date
    var durationMinutes: Int
    var preset: FocusPreset
    var blockedItemsCount: Int
    var shouldNotifyAtEnd: Bool

    init(
        id: UUID = UUID(),
        title: String,
        startedAt: Date,
        endsAt: Date,
        durationMinutes: Int,
        preset: FocusPreset,
        blockedItemsCount: Int,
        shouldNotifyAtEnd: Bool
    ) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.endsAt = endsAt
        self.durationMinutes = durationMinutes
        self.preset = preset
        self.blockedItemsCount = blockedItemsCount
        self.shouldNotifyAtEnd = shouldNotifyAtEnd
    }
}
