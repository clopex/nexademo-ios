//
//  WidgetDataService.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 3. 3. 2026..
//

import Foundation
import WidgetKit

struct WidgetData: Codable {
    var aiScansToday: Int
    var aiScansLimit: Int
    var voiceNotesCount: Int
    var voiceSecondsToday: Int
    var voiceSecondsLimit: Int
    var callsToday: Int
    var isPremium: Bool
    var userName: String
    
    static let `default` = WidgetData(
        aiScansToday: 0,
        aiScansLimit: 5,
        voiceNotesCount: 0,
        voiceSecondsToday: 0,
        voiceSecondsLimit: 60,
        callsToday: 0,
        isPremium: false,
        userName: ""
    )
}

final class WidgetDataService {
    static let shared = WidgetDataService()
    
    private let appGroupID = "group.com.codify.nexademo"
    private let key = "widget_data"
    private let aiScansTodayKey = "widget_ai_scans_today"
    private let aiScansLimitKey = "widget_ai_scans_limit"
    private let voiceNotesCountKey = "widget_voice_notes_count"
    private let voiceSecondsTodayKey = "widget_voice_seconds_today"
    private let voiceSecondsLimitKey = "widget_voice_seconds_limit"
    private let callsTodayKey = "widget_calls_today"
    private let isPremiumKey = "widget_is_premium"
    private let userNameKey = "widget_user_name"
    
    private var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    func save(_ data: WidgetData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        defaults?.set(encoded, forKey: key)
        defaults?.set(data.aiScansToday, forKey: aiScansTodayKey)
        defaults?.set(data.aiScansLimit, forKey: aiScansLimitKey)
        defaults?.set(data.voiceNotesCount, forKey: voiceNotesCountKey)
        defaults?.set(data.voiceSecondsToday, forKey: voiceSecondsTodayKey)
        defaults?.set(data.voiceSecondsLimit, forKey: voiceSecondsLimitKey)
        defaults?.set(data.callsToday, forKey: callsTodayKey)
        defaults?.set(data.isPremium, forKey: isPremiumKey)
        defaults?.set(data.userName, forKey: userNameKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func load() -> WidgetData {
        guard let defaults else { return .default }

        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) {
            return decoded
        }

        if let data = defaults.data(forKey: key),
           let legacy = try? JSONDecoder().decode(LegacyWidgetData.self, from: data) {
            return WidgetData(
                aiScansToday: legacy.aiScansToday,
                aiScansLimit: legacy.aiScansLimit,
                voiceNotesCount: 0,
                voiceSecondsToday: legacy.voiceSecondsToday,
                voiceSecondsLimit: legacy.voiceSecondsLimit,
                callsToday: legacy.callsToday,
                isPremium: legacy.isPremium,
                userName: legacy.userName
            )
        }

        return WidgetData(
            aiScansToday: defaults.integer(forKey: aiScansTodayKey),
            aiScansLimit: value(forKey: aiScansLimitKey, in: defaults, fallback: WidgetData.default.aiScansLimit),
            voiceNotesCount: defaults.integer(forKey: voiceNotesCountKey),
            voiceSecondsToday: defaults.integer(forKey: voiceSecondsTodayKey),
            voiceSecondsLimit: value(forKey: voiceSecondsLimitKey, in: defaults, fallback: WidgetData.default.voiceSecondsLimit),
            callsToday: defaults.integer(forKey: callsTodayKey),
            isPremium: defaults.bool(forKey: isPremiumKey),
            userName: defaults.string(forKey: userNameKey) ?? ""
        )
    }

    func updateAIScanUsage(todayCount: Int, freeLimit: Int = 5) {
        var data = load()
        data.aiScansToday = max(0, todayCount)
        data.aiScansLimit = max(1, freeLimit)
        save(data)
    }

    func syncUsage(
        isPremium: Bool,
        userName: String,
        voiceNotesCount: Int,
        voiceSecondsToday: Int,
        aiScansToday: Int,
        freeScansLimit: Int = 5
    ) {
        var data = load()
        data.isPremium = isPremium
        data.userName = userName
        data.voiceNotesCount = max(0, voiceNotesCount)
        data.voiceSecondsToday = max(0, voiceSecondsToday)
        data.aiScansToday = max(0, aiScansToday)
        data.aiScansLimit = max(1, freeScansLimit)
        data.voiceSecondsLimit = 60
        data.callsToday = 0
        save(data)
    }
}

private struct LegacyWidgetData: Codable {
    var aiScansToday: Int
    var aiScansLimit: Int
    var voiceSecondsToday: Int
    var voiceSecondsLimit: Int
    var callsToday: Int
    var isPremium: Bool
    var userName: String
}

private func value(forKey key: String, in defaults: UserDefaults, fallback: Int) -> Int {
    guard defaults.object(forKey: key) != nil else { return fallback }
    return max(1, defaults.integer(forKey: key))
}
