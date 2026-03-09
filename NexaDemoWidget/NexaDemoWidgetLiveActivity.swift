import ActivityKit
import WidgetKit
import SwiftUI

struct NexaDemoWidgetLiveActivity: Widget {
    private let accentColor = Color("BrandAccent")
    private let activityURL = URL(string: "nexademo://alarm/home")

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReminderAlarmAttributes.self) { context in
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "alarm.fill")
                        .foregroundStyle(accentColor)

                    Text(context.state.label)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(context.state.scheduledAt, style: .time)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }

                Text(context.state.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(context.state.scheduledAt, style: .timer)
                    .font(.title3)
                    .bold()
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .padding(14)
            .activityBackgroundTint(Color.black)
            .activitySystemActionForegroundColor(.white)
            .widgetURL(activityURL)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.label)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.72))
                        Text(context.state.title)
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: 140, alignment: .leading)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.scheduledAt, style: .time)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        Image(systemName: "alarm.fill")
                            .foregroundStyle(accentColor)

                        Text(context.state.scheduledAt, style: .timer)
                            .font(.headline)
                            .bold()
                            .foregroundStyle(.white)
                            .monospacedDigit()

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(accentColor)
            } compactTrailing: {
                Text(context.state.scheduledAt, style: .timer)
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .frame(maxWidth: 48, alignment: .trailing)
            } minimal: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(accentColor)
            }
            .widgetURL(activityURL)
            .keylineTint(accentColor)
        }
    }
}

struct NexaDemoFocusSessionLiveActivity: Widget {
    private let accentColor = Color("BrandAccent")

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusSessionActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(accentColor)

                    Text(context.state.label)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text("Active")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }

                Text(context.state.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack {
                    Text(context.state.endsAt, style: .timer)
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.white)
                        .monospacedDigit()

                    Spacer(minLength: 0)

                    Text("\(context.state.blockedItemsCount) blocked")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
            .padding(14)
            .activityBackgroundTint(Color.black)
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.label)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.72))
                        Text(context.state.title)
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: 150, alignment: .leading)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.endsAt, style: .timer)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        Image(systemName: "shield.fill")
                            .foregroundStyle(accentColor)

                        Text("\(context.state.blockedItemsCount) blocked")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(accentColor)
            } compactTrailing: {
                Text(context.state.endsAt, style: .timer)
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .frame(maxWidth: 48, alignment: .trailing)
            } minimal: {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(accentColor)
            }
            .keylineTint(accentColor)
        }
    }
}

#Preview("Reminder", as: .content, using: ReminderAlarmAttributes(reminderID: UUID())) {
    NexaDemoWidgetLiveActivity()
} contentStates: {
    ReminderAlarmAttributes.ContentState(
        title: "Review the new onboarding copy",
        scheduledAt: Calendar.current.date(byAdding: .minute, value: 45, to: .now) ?? .now,
        remainingSeconds: 2700,
        label: "Next Reminder"
    )
}

#Preview("Focus Session", as: .content, using: FocusSessionActivityAttributes(sessionID: UUID())) {
    NexaDemoFocusSessionLiveActivity()
} contentStates: {
    FocusSessionActivityAttributes.ContentState(
        title: "Study Focus",
        endsAt: Calendar.current.date(byAdding: .minute, value: 35, to: .now) ?? .now,
        blockedItemsCount: 3,
        label: "Focus Session"
    )
}
