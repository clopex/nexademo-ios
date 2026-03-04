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
    var voiceSecondsToday: Int
    var voiceSecondsLimit: Int
    var callsToday: Int
    var isPremium: Bool
    var userName: String
    
    static let `default` = WidgetData(
        aiScansToday: 0,
        aiScansLimit: 5,
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
    
    private var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    func save(_ data: WidgetData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        defaults?.set(encoded, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func load() -> WidgetData {
        guard let data = defaults?.data(forKey: key),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data)
        else { return .default }
        return decoded
    }
}
