import Foundation

enum FreePlanUsageStore {
    static let maxVoiceNotes = 3
    static let maxAIChatMessages = 10

    private static let voiceNotesKey = "freePlanVoiceNotesByUserID"
    private static let aiChatMessagesKey = "freePlanAIChatMessagesByUserID"

    static func voiceNotesCreated(for userID: String) -> Int {
        counts(for: voiceNotesKey)[userID] ?? 0
    }

    static func aiChatMessagesSent(for userID: String) -> Int {
        counts(for: aiChatMessagesKey)[userID] ?? 0
    }

    static func canCreateVoiceNote(for userID: String, isPremium: Bool) -> Bool {
        isPremium || voiceNotesCreated(for: userID) < maxVoiceNotes
    }

    static func canSendAIChatMessage(for userID: String, isPremium: Bool) -> Bool {
        isPremium || aiChatMessagesSent(for: userID) < maxAIChatMessages
    }

    static func registerVoiceNoteCreated(for userID: String) {
        setCount(voiceNotesCreated(for: userID) + 1, for: userID, key: voiceNotesKey)
    }

    static func registerAIChatMessageSent(for userID: String) {
        setCount(aiChatMessagesSent(for: userID) + 1, for: userID, key: aiChatMessagesKey)
    }

    static func syncVoiceNotesCreated(to count: Int, for userID: String) {
        setCount(count, for: userID, key: voiceNotesKey)
    }

    static func syncAIChatMessagesSent(atLeast count: Int, for userID: String) {
        let existingCount = aiChatMessagesSent(for: userID)
        guard count > existingCount else { return }
        setCount(count, for: userID, key: aiChatMessagesKey)
    }

    private static func counts(for key: String) -> [String: Int] {
        UserDefaults.standard.dictionary(forKey: key) as? [String: Int] ?? [:]
    }

    private static func setCount(_ count: Int, for userID: String, key: String) {
        var updatedCounts = counts(for: key)
        updatedCounts[userID] = max(0, count)
        UserDefaults.standard.set(updatedCounts, forKey: key)
    }
}
