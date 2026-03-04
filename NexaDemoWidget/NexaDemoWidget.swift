import WidgetKit
import SwiftUI

// MARK: - Provider
struct NexaDemoProvider: TimelineProvider {
    private let appGroupID = "group.com.codify.nexademo"
    private let payloadKey = "widget_data"
    private let aiScansTodayKey = "widget_ai_scans_today"
    private let aiScansLimitKey = "widget_ai_scans_limit"
    private let voiceNotesCountKey = "widget_voice_notes_count"
    private let voiceSecondsTodayKey = "widget_voice_seconds_today"
    private let voiceSecondsLimitKey = "widget_voice_seconds_limit"
    private let callsTodayKey = "widget_calls_today"
    private let isPremiumKey = "widget_is_premium"
    private let userNameKey = "widget_user_name"

    func placeholder(in context: Context) -> NexaDemoEntry {
        NexaDemoEntry(date: Date(), data: .default)
    }

    func getSnapshot(in context: Context, completion: @escaping (NexaDemoEntry) -> Void) {
        completion(NexaDemoEntry(date: Date(), data: loadData()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NexaDemoEntry>) -> Void) {
        let entry = NexaDemoEntry(date: Date(), data: loadData())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadData() -> WidgetData {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            return .default
        }

        if let data = defaults.data(forKey: payloadKey),
           let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) {
            return decoded
        }

        if let data = defaults.data(forKey: payloadKey),
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
}

// MARK: - Entry
struct NexaDemoEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Widget View
struct NexaDemoWidgetView: View {
    let entry: NexaDemoEntry
    @Environment(\.widgetFamily) var family
    private let widgetBackground = Color.black

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget (2x2)
    private var smallWidget: some View {
        ZStack {
            widgetBackground

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(red: 0.91, green: 0.27, blue: 0.38))
                    Text("NexaDemo")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Spacer()

                statRow(
                    icon: "camera.viewfinder",
                    value: "\(entry.data.aiScansToday)/\(entry.data.isPremium ? "∞" : String(entry.data.aiScansLimit))",
                    label: "Scans"
                )
                statRow(
                    icon: "mic.fill",
                    value: formatVoice(
                        notesCount: entry.data.voiceNotesCount,
                        seconds: entry.data.voiceSecondsToday,
                        limit: entry.data.voiceSecondsLimit,
                        isPremium: entry.data.isPremium
                    ),
                    label: "Voice"
                )
                statRow(
                    icon: "phone.fill",
                    value: "\(entry.data.callsToday) / ∞",
                    label: "Calls"
                )
            }
            .padding(14)
        }
    }

    // MARK: - Medium Widget (4x2)
    private var mediumWidget: some View {
        ZStack {
            widgetBackground

            HStack(spacing: 16) {
                // Left — stats
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(red: 0.91, green: 0.27, blue: 0.38))
                        Text("NexaDemo")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Text("Hey, \(entry.data.userName)!")
                        .font(.system(size: 11))
                        .foregroundStyle(.gray)

                    Spacer()

                    statRow(
                        icon: "camera.viewfinder",
                        value: "\(entry.data.aiScansToday)/\(entry.data.isPremium ? "∞" : String(entry.data.aiScansLimit))",
                        label: "AI Scans"
                    )
                    statRow(
                        icon: "mic.fill",
                        value: formatVoice(
                            notesCount: entry.data.voiceNotesCount,
                            seconds: entry.data.voiceSecondsToday,
                            limit: entry.data.voiceSecondsLimit,
                            isPremium: entry.data.isPremium
                        ),
                        label: "Voice"
                    )
                    statRow(
                        icon: "phone.fill",
                        value: "\(entry.data.callsToday) / ∞",
                        label: "Calls"
                    )
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                // Right — premium status
                VStack(spacing: 8) {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(entry.data.isPremium ?
                                Color(red: 0.06, green: 0.20, blue: 0.38) :
                                Color(red: 0.10, green: 0.10, blue: 0.18))
                            .frame(width: 52, height: 52)
                        Image(systemName: entry.data.isPremium ? "crown.fill" : "lock.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(entry.data.isPremium ?
                                Color(red: 0.00, green: 0.83, blue: 0.67) :
                                Color.gray)
                    }
                    Text(entry.data.isPremium ? "Premium" : "Free Plan")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(entry.data.isPremium ?
                            Color(red: 0.00, green: 0.83, blue: 0.67) :
                            Color.gray)
                    Spacer()
                }
                .frame(maxWidth: 90)
            }
            .padding(14)
        }
    }

    // MARK: - Helpers
    private func statRow(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(Color(red: 0.91, green: 0.27, blue: 0.38))
                .frame(width: 14)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private func formatVoice(notesCount: Int, seconds: Int, limit: Int, isPremium: Bool) -> String {
        let minutes = seconds / 60
        let remaining = seconds % 60
        let padded = remaining < 10 ? "0\(remaining)" : "\(remaining)"
        let duration = "\(minutes):\(padded)"

        if isPremium {
            return "\(notesCount) • \(duration)"
        }
        let limitMinutes = limit / 60
        let limitSeconds = limit % 60
        let paddedLimitSeconds = limitSeconds < 10 ? "0\(limitSeconds)" : "\(limitSeconds)"
        return "\(notesCount) • \(duration)/\(limitMinutes):\(paddedLimitSeconds)"
    }
}

// MARK: - Widget Configuration
struct NexaDemoWidget: Widget {
    let kind: String = "NexaDemoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NexaDemoProvider()) { entry in
            NexaDemoWidgetView(entry: entry)
                .containerBackground(Color.black, for: .widget)
        }
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
        .configurationDisplayName("NexaDemo")
        .description("Track your daily AI usage at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
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

// MARK: - Preview
#Preview(as: .systemMedium) {
    NexaDemoWidget()
} timeline: {
    NexaDemoEntry(date: .now, data: WidgetData(
        aiScansToday: 3,
        aiScansLimit: 5,
        voiceNotesCount: 4,
        voiceSecondsToday: 45,
        voiceSecondsLimit: 60,
        callsToday: 0,
        isPremium: false,
        userName: "Adis"
    ))
}
