import ActivityKit
import Foundation

@MainActor
final class FocusSessionLiveActivityService {
    static let shared = FocusSessionLiveActivityService()

    private init() {}

    func start(for session: FocusSession) async -> String? {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return nil }

        for activity in Activity<FocusSessionActivityAttributes>.activities where activity.attributes.sessionID != session.id {
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        let content = ActivityContent(
            state: makeContentState(for: session),
            staleDate: session.endsAt,
            relevanceScore: 1
        )

        do {
            let activity = try Activity<FocusSessionActivityAttributes>.request(
                attributes: FocusSessionActivityAttributes(sessionID: session.id),
                content: content,
                pushType: nil
            )
            return activity.id
        } catch {
            return nil
        }
    }

    func update(for session: FocusSession) async {
        guard let activity = activity(for: session) else { return }

        let content = ActivityContent(
            state: makeContentState(for: session),
            staleDate: session.endsAt,
            relevanceScore: 1
        )

        await activity.update(content)
    }

    func end(for session: FocusSession, immediate: Bool = true) async {
        guard let activity = activity(for: session) else { return }
        let dismissal: ActivityUIDismissalPolicy = immediate ? .immediate : .default
        await activity.end(nil, dismissalPolicy: dismissal)
    }

    func endExpiredActivities(now: Date = .now) async {
        for activity in Activity<FocusSessionActivityAttributes>.activities where activity.content.state.endsAt <= now {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    func endAllActivities() async {
        for activity in Activity<FocusSessionActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func activity(for session: FocusSession) -> Activity<FocusSessionActivityAttributes>? {
        if let liveActivityID = session.liveActivityID,
           let match = Activity<FocusSessionActivityAttributes>.activities.first(where: { $0.id == liveActivityID }) {
            return match
        }

        return Activity<FocusSessionActivityAttributes>.activities.first(where: { $0.attributes.sessionID == session.id })
    }

    private func makeContentState(for session: FocusSession) -> FocusSessionActivityAttributes.ContentState {
        FocusSessionActivityAttributes.ContentState(
            title: session.title,
            endsAt: session.endsAt,
            blockedItemsCount: session.blockedItemsCount,
            label: "Focus Session"
        )
    }
}
