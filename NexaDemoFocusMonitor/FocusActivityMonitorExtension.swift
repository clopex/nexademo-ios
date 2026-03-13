import ActivityKit
import DeviceActivity
import Foundation
import ManagedSettings

final class FocusActivityMonitorExtension: DeviceActivityMonitor {
    private let defaults = UserDefaults(suiteName: "group.com.codify.nexademo")
    private let storageKey = "focus_session_state"
    private let cleanupKey = "focus_session_live_activity_cleanup"
    private let store = ManagedSettingsStore(named: .init("FocusSession"))

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        guard activity == DeviceActivityName("focus-session-monitor") else {
            return
        }

        store.clearAllSettings()
        defaults?.removeObject(forKey: storageKey)
        defaults?.set(true, forKey: cleanupKey)
        endFocusActivities()
    }

    private func endFocusActivities() {
        for activity in Activity<FocusSessionActivityAttributes>.activities {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
