import DeviceActivity
import Foundation

struct FocusMonitoringService: Sendable {
    static let activityName = DeviceActivityName("focus-session-monitor")
    static let minimumSupportedDuration: TimeInterval = 15 * 60

    private let center = DeviceActivityCenter()

    func startMonitoring(session: FocusSession) throws -> Bool {
        center.stopMonitoring([Self.activityName])

        let sessionDuration = session.endsAt.timeIntervalSince(session.startedAt)
        guard sessionDuration >= Self.minimumSupportedDuration else {
            return false
        }

        let calendar = Calendar.current
        let adjustedStartDate = max(session.startedAt.addingTimeInterval(1), .now.addingTimeInterval(1))
        guard session.endsAt > adjustedStartDate else {
            throw FocusSessionError.invalidDuration
        }

        let startComponents = calendar.dateComponents(
            [.era, .year, .month, .day, .hour, .minute, .second],
            from: adjustedStartDate
        )
        let endComponents = calendar.dateComponents(
            [.era, .year, .month, .day, .hour, .minute, .second],
            from: session.endsAt
        )

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )

        try center.startMonitoring(Self.activityName, during: schedule)
        return true
    }

    func stopMonitoring() {
        center.stopMonitoring([Self.activityName])
    }
}
