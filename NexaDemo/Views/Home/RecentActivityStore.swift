import Foundation

struct StoredRecentActivityEvent: Codable, Sendable {
    let id: UUID
    let userID: String
    let date: Date
    let icon: String
    let colorAssetName: String
    let title: String
    let subtitle: String
}

final class RecentActivityStore {
    static let shared = RecentActivityStore()

    private let key = "recent_activity_events"
    private let maxStoredEvents = 40

    func recordAIScan(userID: String, objects: [DetectedObject]) {
        let topObject = objects.first
        let title = topObject.map { "\($0.label.capitalized) scanned" } ?? "Object scanned"
        let subtitle = topObject.map { "Confidence: \($0.confidencePercentage)" } ?? "AI camera finished a scan"

        append(
            StoredRecentActivityEvent(
                id: UUID(),
                userID: userID,
                date: .now,
                icon: "camera.viewfinder",
                colorAssetName: "BrandAccent",
                title: title,
                subtitle: subtitle
            )
        )
    }

    func recordAIChatMessage(userID: String, message: String) {
        let preview = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let subtitle = preview.isEmpty ? "You sent a message to AI" : String(preview.prefix(40))

        append(
            StoredRecentActivityEvent(
                id: UUID(),
                userID: userID,
                date: .now,
                icon: "bubble.left.and.bubble.right.fill",
                colorAssetName: "PremiumGradientEnd",
                title: "AI message sent",
                subtitle: subtitle
            )
        )
    }

    func recordNexaCommand(userID: String, title: String, subtitle: String) {
        append(
            StoredRecentActivityEvent(
                id: UUID(),
                userID: userID,
                date: .now,
                icon: "sparkles",
                colorAssetName: "SuccessAccent",
                title: title,
                subtitle: subtitle
            )
        )
    }

    func recordCallStarted(userID: String, contactName: String) {
        append(
            StoredRecentActivityEvent(
                id: UUID(),
                userID: userID,
                date: .now,
                icon: "phone.fill",
                colorAssetName: "BrandAccent",
                title: "Call started",
                subtitle: contactName
            )
        )
    }

    func events(for userID: String?) -> [StoredRecentActivityEvent] {
        guard let userID else { return [] }
        return loadEvents()
            .filter { $0.userID == userID }
            .sorted { $0.date > $1.date }
    }

    private func append(_ event: StoredRecentActivityEvent) {
        var updatedEvents = loadEvents()
        updatedEvents.append(event)
        updatedEvents = Array(updatedEvents.sorted { $0.date > $1.date }.prefix(maxStoredEvents))
        saveEvents(updatedEvents)
        NotificationCenter.default.post(name: .recentActivityDidChange, object: nil)
    }

    private func loadEvents() -> [StoredRecentActivityEvent] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([StoredRecentActivityEvent].self, from: data) else {
            return []
        }
        return decoded
    }

    private func saveEvents(_ events: [StoredRecentActivityEvent]) {
        guard let encoded = try? JSONEncoder().encode(events) else { return }
        UserDefaults.standard.set(encoded, forKey: key)
    }
}

extension Notification.Name {
    static let recentActivityDidChange = Notification.Name("recentActivityDidChange")
}
