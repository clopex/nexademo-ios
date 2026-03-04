import Foundation

final class AIScanAttemptStore {
    static let shared = AIScanAttemptStore()

    private let appGroupID = "group.com.codify.nexademo"
    private let countKey = "ai_scans_today_count"
    private let dateKey = "ai_scans_today_date"

    private var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    func todayCount() -> Int {
        resetIfNeeded()
        return defaults.integer(forKey: countKey)
    }

    func canStartScan(isPremium: Bool, freeLimit: Int = 5) -> Bool {
        isPremium || todayCount() < freeLimit
    }

    @discardableResult
    func registerScanAttempt() -> Int {
        resetIfNeeded()
        let next = defaults.integer(forKey: countKey) + 1
        defaults.set(next, forKey: countKey)
        return next
    }

    private func resetIfNeeded(referenceDate: Date = Date()) {
        let storedDate = defaults.object(forKey: dateKey) as? Date
        if let storedDate, Calendar.current.isDate(storedDate, inSameDayAs: referenceDate) {
            return
        }

        defaults.set(referenceDate, forKey: dateKey)
        defaults.set(0, forKey: countKey)
    }
}
