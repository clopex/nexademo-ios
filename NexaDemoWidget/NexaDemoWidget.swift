import WidgetKit
import SwiftUI

// MARK: - Provider
struct NexaDemoProvider: TimelineProvider {
    private let appGroupID = "group.com.codify.nexademo"
    private let key = "widget_data"

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
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data)
        else { return .default }
        return decoded
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
            Color(red: 0.04, green: 0.04, blue: 0.06)

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
                    value: formatVoice(entry.data.voiceSecondsToday, limit: entry.data.voiceSecondsLimit, isPremium: entry.data.isPremium),
                    label: "Voice"
                )
                statRow(
                    icon: "phone.fill",
                    value: entry.data.isPremium ? "\(entry.data.callsToday)" : "—",
                    label: "Calls"
                )
            }
            .padding(14)
        }
    }

    // MARK: - Medium Widget (4x2)
    private var mediumWidget: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.06)

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
                        value: formatVoice(entry.data.voiceSecondsToday, limit: entry.data.voiceSecondsLimit, isPremium: entry.data.isPremium),
                        label: "Voice"
                    )
                    statRow(
                        icon: "phone.fill",
                        value: entry.data.isPremium ? "\(entry.data.callsToday)" : "Locked",
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

    private func formatVoice(_ seconds: Int, limit: Int, isPremium: Bool) -> String {
        if isPremium { return "\(seconds / 60):\(String(format: "%02d", seconds % 60))" }
        return "\(seconds / 60):\(String(format: "%02d", seconds % 60))/1:00"
    }
}

// MARK: - Widget Configuration
struct NexaDemoWidget: Widget {
    let kind: String = "NexaDemoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NexaDemoProvider()) { entry in
            NexaDemoWidgetView(entry: entry)
                .containerBackground(Color(red: 0.04, green: 0.04, blue: 0.06), for: .widget)
        }
        .configurationDisplayName("NexaDemo")
        .description("Track your daily AI usage at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview
#Preview(as: .systemMedium) {
    NexaDemoWidget()
} timeline: {
    NexaDemoEntry(date: .now, data: WidgetData(
        aiScansToday: 3,
        aiScansLimit: 5,
        voiceSecondsToday: 45,
        voiceSecondsLimit: 60,
        callsToday: 0,
        isPremium: false,
        userName: "Adis"
    ))
}
