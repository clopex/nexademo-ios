import DeviceActivity
import Foundation
import ManagedSettings

final class FocusActivityMonitorExtension: DeviceActivityMonitor {
    private let defaults = UserDefaults(suiteName: "group.com.codify.nexademo")
    private let storageKey = "focus_session_state"
    private let store = ManagedSettingsStore(named: .init("FocusSession"))

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        guard activity == DeviceActivityName("focus-session-monitor") else {
            return
        }

        store.clearAllSettings()
        defaults?.removeObject(forKey: storageKey)
    }
}
