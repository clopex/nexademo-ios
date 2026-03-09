import Foundation

struct RecentActivityService: Sendable {
    func makeItems(
        voiceNotes: [VoiceNote],
        reminders: [VoiceNoteReminder],
        activeFocusSession: FocusSession?
    ) -> [ActivityItem] {
        var events: [RecentActivityEvent] = []

        events.append(contentsOf: voiceNotes.map(makeVoiceNoteEvent))
        events.append(contentsOf: reminders.map(makeReminderEvent))

        if let activeFocusSession {
            events.append(makeFocusEvent(from: activeFocusSession))
        }

        return events
            .sorted { $0.date > $1.date }
            .prefix(5)
            .map(\.item)
    }

    private func makeVoiceNoteEvent(from note: VoiceNote) -> RecentActivityEvent {
        let duration = VoiceNoteDurationStore.duration(for: note.id)
            ?? estimateDuration(from: note.text)
        let preview = note.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let subtitle = preview.isEmpty
            ? "Duration: \(formattedDuration(duration))"
            : "\(preview.prefix(36))"

        return RecentActivityEvent(
            date: note.createdAt,
            item: ActivityItem(
                icon: "mic.fill",
                colorAssetName: "PremiumGradientEnd",
                title: "Voice note saved",
                subtitle: subtitle,
                time: relativeTimestamp(for: note.createdAt)
            )
        )
    }

    private func makeReminderEvent(from reminder: VoiceNoteReminder) -> RecentActivityEvent {
        let formatter = Date.FormatStyle(date: .abbreviated, time: .shortened)

        return RecentActivityEvent(
            date: reminder.createdAt,
            item: ActivityItem(
                icon: "alarm.fill",
                colorAssetName: "BrandAccent",
                title: reminder.isEnabled ? "Reminder scheduled" : "Reminder disabled",
                subtitle: reminder.scheduledAt.formatted(formatter),
                time: relativeTimestamp(for: reminder.createdAt)
            )
        )
    }

    private func makeFocusEvent(from session: FocusSession) -> RecentActivityEvent {
        RecentActivityEvent(
            date: session.startedAt,
            item: ActivityItem(
                icon: "brain.head.profile",
                colorAssetName: "SuccessAccent",
                title: session.title,
                subtitle: "Focus active until \(session.endsAt.formatted(date: .omitted, time: .shortened))",
                time: relativeTimestamp(for: session.startedAt)
            )
        )
    }

    private func relativeTimestamp(for date: Date) -> String {
        date.formatted(.relative(presentation: .named))
    }

    private func estimateDuration(from text: String) -> TimeInterval {
        let words = text.split(separator: " ").count
        guard words > 0 else { return 0 }
        return Double(words) / 2.4
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let clamped = max(0, Int(seconds.rounded()))
        let minutes = clamped / 60
        let remainingSeconds = clamped % 60
        let paddedSeconds = remainingSeconds < 10 ? "0\(remainingSeconds)" : "\(remainingSeconds)"
        return "\(minutes):\(paddedSeconds)"
    }
}

private struct RecentActivityEvent: Sendable {
    let date: Date
    let item: ActivityItem
}
