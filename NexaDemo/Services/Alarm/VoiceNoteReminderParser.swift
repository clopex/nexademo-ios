import Foundation

struct VoiceNoteReminderCandidate: Identifiable, Sendable {
    let id = UUID()
    let suggestedTitle: String
    let suggestedDate: Date
    let confidence: Double
}

struct VoiceNoteReminderParser: Sendable {
    func parseCandidate(from text: String, now: Date = .now) -> VoiceNoteReminderCandidate? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }

        let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
        guard let match = detector.matches(in: trimmed, options: [], range: range).first,
              var date = match.date else {
            return nil
        }

        if date <= now {
            if containsOnlyTimeReference(in: trimmed) {
                date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
            } else {
                return nil
            }
        }

        guard date > now else { return nil }

        return VoiceNoteReminderCandidate(
            suggestedTitle: defaultTitle(from: trimmed),
            suggestedDate: date,
            confidence: match.duration > 0 ? 0.95 : 0.8
        )
    }

    func defaultTitle(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Voice Note Reminder" }

        let normalized = trimmed.replacingOccurrences(of: "\n", with: " ")
        let title = normalized.count > 48 ? String(normalized.prefix(48)).trimmingCharacters(in: .whitespacesAndNewlines) : normalized
        return title.isEmpty ? "Voice Note Reminder" : title
    }

    private func containsOnlyTimeReference(in text: String) -> Bool {
        let lowercased = text.lowercased()
        let dateKeywords = [
            "tomorrow", "today", "monday", "tuesday", "wednesday", "thursday",
            "friday", "saturday", "sunday", "jan", "feb", "mar", "apr", "may",
            "jun", "jul", "aug", "sep", "oct", "nov", "dec", "next", "/"
        ]

        return !dateKeywords.contains { lowercased.localizedStandardContains($0) }
    }
}
