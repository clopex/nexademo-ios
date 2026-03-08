import Foundation

enum AlarmRoute {
    static let scheme = "nexademo"
    static let host = "alarm"
    static let homePath = "/home"
    static let homeURL = URL(string: "\(scheme)://\(host)\(homePath)")!
    static let appGroupSuite = "group.com.codify.nexademo"
    static let pendingHomeOpenKey = "pendingReminderAlarmHomeOpen"
}

@MainActor
@Observable
final class AlarmLaunchRouter {
    func handle(_ url: URL, tabRouter: AppTabRouter) -> Bool {
        guard url.scheme == AlarmRoute.scheme, url.host == AlarmRoute.host, url.path == AlarmRoute.homePath else {
            return false
        }
        tabRouter.reset()
        return true
    }

    func consumePendingLaunch(tabRouter: AppTabRouter) -> Bool {
        guard let defaults = UserDefaults(suiteName: AlarmRoute.appGroupSuite),
              defaults.bool(forKey: AlarmRoute.pendingHomeOpenKey)
        else {
            return false
        }

        defaults.set(false, forKey: AlarmRoute.pendingHomeOpenKey)
        tabRouter.openHome()
        return true
    }
}
