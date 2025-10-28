import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Attributes (data model for the live activity)
struct PrayerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var upcomingPrayer: String
        var remainingTime: TimeInterval // seconds left
        var upcomingTime: String
    }

    var location: String
}

// MARK: - Live Activity Widget
@available(iOS 16.1, *)
struct PrayerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerActivityAttributes.self) { context in
            // Lock screen + Live Activity view
            VStack(alignment: .center, spacing: 6) {
                Text("🕌 \(context.state.upcomingPrayer)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.green)

                Text(formatRemainingTime(context.state.remainingTime))
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text("حتى صلاة \(context.state.upcomingPrayer) في \(context.state.upcomingTime)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .activityBackgroundTint(Color(red: 21/255, green: 21/255, blue: 21/255))
            .activitySystemActionForegroundColor(.green)
        } dynamicIsland: { context in
            // Dynamic Island layout (optional)
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("🕌 \(context.state.upcomingPrayer)")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatRemainingTime(context.state.remainingTime))
                        .monospacedDigit()
                        .font(.title2)
                }
            } compactLeading: {
                Text("🕌")
            } compactTrailing: {
                Text(shortRemaining(context.state.remainingTime))
            } minimal: {
                Text(shortRemaining(context.state.remainingTime))
            }
        }
    }
}

// MARK: - Helper functions
func formatRemainingTime(_ seconds: TimeInterval) -> String {
    let intSec = Int(seconds)
    let h = intSec / 3600
    let m = (intSec % 3600) / 60
    let s = intSec % 60
    if h > 0 {
        return String(format: "%02d:%02d:%02d", h, m, s)
    } else {
        return String(format: "%02d:%02d", m, s)
    }
}

func shortRemaining(_ seconds: TimeInterval) -> String {
    let intSec = Int(seconds)
    let m = (intSec % 3600) / 60
    return "\(m)m"
}
