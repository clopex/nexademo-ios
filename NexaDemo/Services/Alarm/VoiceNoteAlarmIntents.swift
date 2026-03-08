import AlarmKit
import AppIntents
import SwiftUI

private enum AlarmLaunchDefaults {
    static let suiteName = "group.com.codify.nexademo"
    static let pendingHomeOpenKey = "pendingReminderAlarmHomeOpen"
}

struct OpenReminderIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Open App"
    static var description = IntentDescription("Open NexaDemo from a reminder alarm.")
    static var openAppWhenRun = true

    @Parameter(title: "Alarm ID")
    var alarmID: String

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    init() {
        self.alarmID = ""
    }

    func perform() throws -> some IntentResult {
        let id = try alarmUUID()
        UserDefaults(suiteName: AlarmLaunchDefaults.suiteName)?
            .set(true, forKey: AlarmLaunchDefaults.pendingHomeOpenKey)
        try AlarmManager.shared.stop(id: id)
        return .result()
    }

    private func alarmUUID() throws -> UUID {
        guard let uuid = UUID(uuidString: alarmID) else {
            throw AlarmIntentError.invalidAlarmID
        }
        return uuid
    }
}

private enum AlarmIntentError: Error {
    case invalidAlarmID
}

extension AlarmButton {
    static var stopReminderButton: Self {
        AlarmButton(text: "Done", textColor: .white, systemImageName: "stop.circle.fill")
    }

    static var openReminderButton: Self {
        AlarmButton(text: "Open", textColor: .black, systemImageName: "app.fill")
    }
}
