import Foundation

enum VoiceNoteDurationStore {
    private static let key = "voice_note_durations"

    static func setDuration(_ duration: TimeInterval, for noteID: UUID) {
        var map = loadMap()
        map[noteID.uuidString] = max(0, duration)
        saveMap(map)
    }

    static func removeDuration(for noteID: UUID) {
        var map = loadMap()
        map.removeValue(forKey: noteID.uuidString)
        saveMap(map)
    }

    static func duration(for noteID: UUID) -> TimeInterval? {
        loadMap()[noteID.uuidString]
    }

    static func totalDuration(for notes: [VoiceNote]) -> TimeInterval {
        notes.reduce(0) { partial, note in
            partial + (duration(for: note.id) ?? estimatedDuration(from: note.text))
        }
    }

    private static func estimatedDuration(from text: String) -> TimeInterval {
        let words = text.split(separator: " ").count
        guard words > 0 else { return 0 }

        let wordsPerSecond = 2.4
        return Double(words) / wordsPerSecond
    }

    private static func loadMap() -> [String: TimeInterval] {
        UserDefaults.standard.dictionary(forKey: key) as? [String: TimeInterval] ?? [:]
    }

    private static func saveMap(_ map: [String: TimeInterval]) {
        UserDefaults.standard.set(map, forKey: key)
    }
}
