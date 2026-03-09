import DeviceActivity
import Foundation

struct FocusMonitoringService: Sendable {
    static let activityName = DeviceActivityName("focus-session-monitor")

    private let center = DeviceActivityCenter()

    func startMonitoring(session: FocusSession) throws {
        center.stopMonitoring([Self.activityName])

        let calendar = Calendar.current
        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(
                in: .current,
                from: session.startedAt
            ),
            intervalEnd: calendar.dateComponents(
                in: .current,
                from: session.endsAt
            ),
            repeats: false
        )

        try center.startMonitoring(Self.activityName, during: schedule)
    }

    func stopMonitoring() {
        center.stopMonitoring([Self.activityName])
    }
}
