import Foundation

struct NexaPlacesIntentParser: Sendable {
    func parse(_ transcript: String) -> NexaPlacesIntent {
        let spokenQuery = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedQuery = normalizedQuery(from: spokenQuery)

        return NexaPlacesIntent(
            spokenQuery: spokenQuery,
            searchQuery: normalizedQuery.isEmpty ? "coffee shop" : normalizedQuery
        )
    }

    private func normalizedQuery(from transcript: String) -> String {
        let lowered = transcript.lowercased()
        let withoutPrefix = removingPrefix(from: lowered)
        let withoutSuffix = removingSuffix(from: withoutPrefix)
        let cleaned = withoutSuffix.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))

        switch cleaned {
        case "coffee", "coffee shop", "coffee shops", "cafe", "cafes":
            return "coffee shop"
        case "gym", "gyms", "fitness", "fitness center":
            return "gym"
        case "restaurants", "restaurant", "food":
            return "restaurant"
        case "pharmacy", "pharmacies":
            return "pharmacy"
        default:
            return cleaned
        }
    }

    private func removingPrefix(from transcript: String) -> String {
        let prefixes = [
            "find me ",
            "find ",
            "show me ",
            "show ",
            "search for ",
            "look for ",
            "locate "
        ]

        for prefix in prefixes where transcript.hasPrefix(prefix) {
            return String(transcript.dropFirst(prefix.count))
        }

        return transcript
    }

    private func removingSuffix(from transcript: String) -> String {
        let suffixes = [
            " near me",
            " around me",
            " nearby",
            " close by",
            " in my area"
        ]

        for suffix in suffixes where transcript.hasSuffix(suffix) {
            return String(transcript.dropLast(suffix.count))
        }

        return transcript
    }
}
