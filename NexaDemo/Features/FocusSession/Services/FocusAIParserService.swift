import Foundation

struct FocusAIParserService: Sendable {
    func defaultProposal() -> FocusSessionProposal {
        makeProposal(preset: .deepWork, durationMinutes: 25, sourceText: nil)
    }

    func proposal(for text: String) -> FocusSessionProposal? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return nil }

        let normalized = trimmedText.localizedLowercase
        let preset = detectedPreset(in: normalized)
        let durationMinutes = detectedDuration(in: normalized) ?? defaultDuration(for: preset)

        guard isFocusIntent(normalized) || detectedPreset(in: normalized) != .custom else {
            return nil
        }

        return makeProposal(preset: preset, durationMinutes: durationMinutes, sourceText: trimmedText)
    }

    private func makeProposal(
        preset: FocusPreset,
        durationMinutes: Int,
        sourceText: String?
    ) -> FocusSessionProposal {
        FocusSessionProposal(
            title: preset.title,
            durationMinutes: min(max(durationMinutes, 5), 180),
            preset: preset,
            suggestedCategories: preset.suggestedBlocks,
            shouldSuggestEndReminder: true,
            sourceText: sourceText
        )
    }

    private func isFocusIntent(_ normalized: String) -> Bool {
        normalized.localizedStandardContains("focus")
            || normalized.localizedStandardContains("study")
            || normalized.localizedStandardContains("deep work")
            || normalized.localizedStandardContains("reading")
            || normalized.localizedStandardContains("block distractions")
            || normalized.localizedStandardContains("call prep")
    }

    private func detectedPreset(in normalized: String) -> FocusPreset {
        if normalized.localizedStandardContains("study") || normalized.localizedStandardContains("exam") {
            return .study
        }

        if normalized.localizedStandardContains("deep work") || normalized.localizedStandardContains("work") {
            return .deepWork
        }

        if normalized.localizedStandardContains("read") || normalized.localizedStandardContains("reading") {
            return .reading
        }

        if normalized.localizedStandardContains("call") || normalized.localizedStandardContains("meeting") {
            return .callPrep
        }

        return .custom
    }

    private func defaultDuration(for preset: FocusPreset) -> Int {
        switch preset {
        case .study:
            return 40
        case .deepWork:
            return 25
        case .reading:
            return 30
        case .callPrep:
            return 15
        case .custom:
            return 25
        }
    }

    private func detectedDuration(in normalized: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: #"(\d+)\s*(minute|minutes|min|hour|hours|hr|hrs)"#) else {
            return nil
        }

        let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
        guard let match = regex.firstMatch(in: normalized, range: range),
              let numberRange = Range(match.range(at: 1), in: normalized),
              let unitRange = Range(match.range(at: 2), in: normalized),
              let value = Int(normalized[numberRange]) else {
            return nil
        }

        let unit = String(normalized[unitRange])
        if unit.localizedStandardContains("hour") || unit.localizedStandardContains("hr") {
            return value * 60
        }

        return value
    }
}
