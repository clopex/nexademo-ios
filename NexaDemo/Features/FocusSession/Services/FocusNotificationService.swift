import Foundation
import UserNotifications

struct FocusNotificationService: Sendable {
    func scheduleEndNotification(for session: FocusSession) async {
        let center = UNUserNotificationCenter.current()

        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            break
        case .notDetermined:
            let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted == true else { return }
        case .denied:
            return
        @unknown default:
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Focus Session Complete"
        content.body = "\(session.title) just finished. Ready to jump back in?"
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: session.endsAt
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: session.id),
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    func cancelEndNotification(for sessionID: UUID) async {
        let identifier = notificationIdentifier(for: sessionID)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    private func notificationIdentifier(for sessionID: UUID) -> String {
        "focus-session-\(sessionID.uuidString)"
    }
}
