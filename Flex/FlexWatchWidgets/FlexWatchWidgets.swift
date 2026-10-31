import SwiftUI
import WidgetKit

/// The watch-face complication (STORY_011): workouts this week against the target, read from the App
/// Group the watch app writes after every snapshot. A tap opens Flex.
@main
struct FlexWatchWidgets: WidgetBundle {
    var body: some Widget {
        WeekProgressWidget()
    }
}

struct WeekProgressEntry: TimelineEntry {
    let date: Date
    let progress: WeekProgress
}

struct WeekProgressProvider: TimelineProvider {
    private func current() -> WeekProgress {
        UserDefaults(suiteName: WeekProgress.appGroup).map(WeekProgress.read(from:)) ?? .empty
    }

    func placeholder(in context: Context) -> WeekProgressEntry {
        WeekProgressEntry(date: .now, progress: WeekProgress(workoutsThisWeek: 2, weeklyTarget: 3))
    }

    func getSnapshot(in context: Context, completion: @escaping (WeekProgressEntry) -> Void) {
        completion(WeekProgressEntry(date: .now, progress: context.isPreview ? placeholder(in: context).progress : current()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeekProgressEntry>) -> Void) {
        // One entry; the watch app asks for a reload whenever the numbers change.
        completion(Timeline(entries: [WeekProgressEntry(date: .now, progress: current())], policy: .never))
    }
}

struct WeekProgressWidget: Widget {
    let kind = "WeekProgress"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeekProgressProvider()) { entry in
            WeekProgressView(progress: entry.progress)
        }
        .configurationDisplayName("This Week")
        .description("Workouts this week against your target. Tap to open Flex.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryRectangular])
    }
}

struct WeekProgressView: View {
    @Environment(\.widgetFamily) private var family
    let progress: WeekProgress

    private var tint: Color { progress.isMet ? .green : .blue }

    var body: some View {
        Group {
            switch family {
            case .accessoryCorner:
                Text(progress.label)
                    .font(.system(.title3, design: .rounded))
                    .monospacedDigit()
                    .widgetCurvesContent()
                    .widgetLabel {
                        Gauge(value: progress.fraction) { Text("Flex") }
                            .tint(tint)
                    }
            case .accessoryRectangular:
                HStack(spacing: 8) {
                    ring
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Flex")
                            .font(.headline)
                        Text(progress.text)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            default:
                ring
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .accessibilityLabel(progress.text)
    }

    private var ring: some View {
        Gauge(value: progress.fraction) {
            Image(systemName: "dumbbell.fill")
        } currentValueLabel: {
            Text(progress.label)
                .font(.system(.caption, design: .rounded))
                .monospacedDigit()
        }
        .gaugeStyle(.accessoryCircular)
        .tint(tint)
    }
}

#Preview("Circular", as: .accessoryCircular) {
    WeekProgressWidget()
} timeline: {
    WeekProgressEntry(date: .now, progress: WeekProgress(workoutsThisWeek: 2, weeklyTarget: 3))
    WeekProgressEntry(date: .now, progress: WeekProgress(workoutsThisWeek: 3, weeklyTarget: 3))
    WeekProgressEntry(date: .now, progress: .empty)
}
