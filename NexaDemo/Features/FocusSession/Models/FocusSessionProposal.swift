import Foundation

struct FocusSessionProposal: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    var title: String
    var durationMinutes: Int
    var preset: FocusPreset
    var suggestedCategories: [String]
    var shouldSuggestEndReminder: Bool
    var sourceText: String?

    init(
        id: UUID = UUID(),
        title: String,
        durationMinutes: Int,
        preset: FocusPreset,
        suggestedCategories: [String],
        shouldSuggestEndReminder: Bool,
        sourceText: String? = nil
    ) {
        self.id = id
        self.title = title
        self.durationMinutes = durationMinutes
        self.preset = preset
        self.suggestedCategories = suggestedCategories
        self.shouldSuggestEndReminder = shouldSuggestEndReminder
        self.sourceText = sourceText
    }
}
