import AlarmKit
import ActivityKit
import Foundation
import SwiftUI

enum AlarmServiceError: LocalizedError {
    case unavailable
    case unauthorized
    case maximumLimitReached
    case systemError(String)

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Alarm scheduling is unavailable on this device."
        case .unauthorized:
            return "Alarm access was denied."
        case .maximumLimitReached:
            return "You have reached the system limit for app alarms. Remove an existing NexaDemo alarm and try again."
        case .systemError(let message):
            return message
        }
    }
}

@MainActor
final class AlarmService {
    static let shared = AlarmService()

    private let manager = AlarmManager.shared

    private init() {}

    func ensureAuthorization() async throws {
        let state = manager.authorizationState
        switch state {
        case .authorized:
            return
        case .notDetermined:
            return
        case .denied:
            throw AlarmServiceError.unauthorized
        @unknown default:
            throw AlarmServiceError.unavailable
        }
    }

    func schedule(reminder: VoiceNoteReminder) async throws -> UUID {
        try await ensureAuthorization()
        try clearExistingAppAlarms(excluding: reminder.systemAlarmID)

        let alarmID = reminder.systemAlarmID ?? UUID()
        let attributes = AlarmAttributes(
            presentation: makePresentation(),
            metadata: VoiceNoteAlarmMetadata(reminderID: reminder.id, title: reminder.title),
            tintColor: Color("BrandAccent")
        )

        let configuration = AlarmManager.AlarmConfiguration.alarm(
            schedule: .fixed(reminder.scheduledAt),
            attributes: attributes,
            secondaryIntent: OpenReminderIntent(alarmID: alarmID.uuidString),
            sound: .default
        )

        do {
            _ = try await manager.schedule(id: alarmID, configuration: configuration)
            return alarmID
        } catch let error as AlarmManager.AlarmError {
            switch error {
            case .maximumLimitReached:
                throw AlarmServiceError.maximumLimitReached
            @unknown default:
                throw AlarmServiceError.unavailable
            }
        } catch {
            throw error
        }
    }

    func cancelAlarm(id: UUID?) {
        guard let id else { return }
        try? manager.cancel(id: id)
    }

    private func clearExistingAppAlarms(excluding excludedID: UUID?) throws {
        let existingAlarms = try manager.alarms

        for alarm in existingAlarms where alarm.id != excludedID {
            try? manager.cancel(id: alarm.id)
        }
    }

    private func makePresentation() -> AlarmPresentation {
        let alert: AlarmPresentation.Alert
        if #available(iOS 26.1, *) {
            alert = .init(
                title: "Voice Note Reminder",
                secondaryButton: .openReminderButton,
                secondaryButtonBehavior: .custom
            )
        } else {
            alert = .init(
                title: "Voice Note Reminder",
                stopButton: .stopReminderButton,
                secondaryButton: .openReminderButton,
                secondaryButtonBehavior: .custom
            )
        }

        return AlarmPresentation(alert: alert)
    }
}
