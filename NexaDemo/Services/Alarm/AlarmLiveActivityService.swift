import ActivityKit
import Foundation

@MainActor
final class AlarmLiveActivityService {
    static let shared = AlarmLiveActivityService()

    private init() {}

    func start(for reminder: VoiceNoteReminder) async -> String? {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return nil }

        for activity in Activity<ReminderAlarmAttributes>.activities where activity.attributes.reminderID != reminder.id {
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        let content = ActivityContent(
            state: makeContentState(for: reminder),
            staleDate: reminder.scheduledAt,
            relevanceScore: 1
        )

        do {
            let activity = try Activity<ReminderAlarmAttributes>.request(
                attributes: ReminderAlarmAttributes(reminderID: reminder.id),
                content: content,
                pushType: nil
            )
            return activity.id
        } catch {
            return nil
        }
    }

    func update(for reminder: VoiceNoteReminder) async {
        guard let activity = activity(for: reminder) else { return }

        let content = ActivityContent(
            state: makeContentState(for: reminder),
            staleDate: reminder.scheduledAt,
            relevanceScore: 1
        )

        await activity.update(content)
    }

    func end(for reminder: VoiceNoteReminder, immediate: Bool = true) async {
        guard let activity = activity(for: reminder) else { return }
        let dismissal: ActivityUIDismissalPolicy = immediate ? .immediate : .default
        await activity.end(nil, dismissalPolicy: dismissal)
    }

    func endExpiredActivities(now: Date = .now) async {
        for activity in Activity<ReminderAlarmAttributes>.activities {
            if activity.content.state.scheduledAt <= now {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    func endAllActivities() async {
        for activity in Activity<ReminderAlarmAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func activity(for reminder: VoiceNoteReminder) -> Activity<ReminderAlarmAttributes>? {
        if let liveActivityID = reminder.liveActivityID,
           let match = Activity<ReminderAlarmAttributes>.activities.first(where: { $0.id == liveActivityID }) {
            return match
        }

        return Activity<ReminderAlarmAttributes>.activities.first(where: { $0.attributes.reminderID == reminder.id })
    }

    private func makeContentState(for reminder: VoiceNoteReminder) -> ReminderAlarmAttributes.ContentState {
        let remaining = max(0, Int(reminder.scheduledAt.timeIntervalSinceNow.rounded()))
        return ReminderAlarmAttributes.ContentState(
            title: reminder.title,
            scheduledAt: reminder.scheduledAt,
            remainingSeconds: remaining,
            label: "Next Reminder"
        )
    }
}
