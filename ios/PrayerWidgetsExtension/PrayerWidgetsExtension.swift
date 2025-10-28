import WidgetKit
import SwiftUI
import Intents

// MARK: - Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            upcomingPrayer: "الصلاة القادمة",
            upcomingTime: "--:--",
            allPrayers: defaultPrayers()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(loadPrayerData())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = loadPrayerData()
        WidgetCenter.shared.reloadAllTimelines()
        completion(Timeline(entries: [entry], policy: .never))
    }

    func loadPrayerData() -> SimpleEntry {
        // ⚠️ Make sure this matches your App Group ID
        let defaults = UserDefaults(suiteName: "group.com.example.mostakeem")

        let upcomingPrayer = defaults?.string(forKey: "prayer_name") ?? "الصلاة القادمة"
        let upcomingTime = defaults?.string(forKey: "prayer_time") ?? "--:--"
        let allPrayers = defaults?.dictionary(forKey: "all_prayers") as? [String: String] ?? defaultPrayers()

        return SimpleEntry(
            date: Date(),
            upcomingPrayer: upcomingPrayer,
            upcomingTime: upcomingTime,
            allPrayers: allPrayers
        )
    }

    func defaultPrayers() -> [String: String] {
        [
            "منتصف الليل": "--:--",
            "الثلث الاخير": "--:--",
            "الفجر": "--:--",
            "الشروق": "--:--",
            "الظهر": "--:--",
            "العصر": "--:--",
            "المغرب": "--:--",
            "العشاء": "--:--"
        ]
    }
}

// MARK: - Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let upcomingPrayer: String
    let upcomingTime: String
    let allPrayers: [String: String]
}

// MARK: - Gradient Background
let prayerGradient = LinearGradient(
    gradient: Gradient(colors: [
        Color(red: 21/255, green: 21/255, blue: 21/255),
        Color(red: 0/255, green: 85/255, blue: 70/255)
    ]),
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// MARK: - Small Widget View
struct SmallPrayerView: View {
    var entry: SimpleEntry

    var body: some View {
        VStack(spacing: 6) {
            Text("🕌 \(entry.upcomingPrayer)")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            Text(entry.upcomingTime)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.green)
                .shadow(color: .green.opacity(0.4), radius: 3)

            Text("حان وقت الصلاة ⏱️")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            prayerGradient
        }
    }
}

// MARK: - Medium Widget View
struct MediumPrayerView: View {
    var entry: SimpleEntry

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // Dark left side with gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 21/255, green: 21/255, blue: 21/255),
                        Color(red: 0/255, green: 85/255, blue: 70/255)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                    .frame(maxWidth: .infinity)

                // Light right side
                Color(red: 245/255, green: 245/255, blue: 245/255)
                    .frame(maxWidth: .infinity)
            }

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.upcomingPrayer)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.green)

                    Text("..." + entry.upcomingTime)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)

                    Text(formattedDate())
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.leading, 16)
                .padding(.vertical, 12)

                Spacer()

                VStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("الصلاة التالية")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                        Image(systemName: "moon.stars.fill")
                            .foregroundColor(.orange)
                    }

                    VStack(spacing: 4) {
                        Text(calculateTimeRemaining())
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(Color(red: 21/255, green: 21/255, blue: 21/255)))

                    Text("القاهرة")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0/255, green: 150/255, blue: 180/255))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.trailing, 16)
                .padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) { Color.clear }
    }

    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM yyyy"
        formatter.locale = Locale(identifier: "ar_EG")
        return formatter.string(from: entry.date)
    }

    func calculateTimeRemaining() -> String {
        let comps = entry.upcomingTime.split(separator: ":")
        guard comps.count == 2,
              let hour = Int(comps[0]),
              let min = Int(comps[1]) else { return "00:00" }

        let now = Date()
        let cal = Calendar.current
        let nowComps = cal.dateComponents([.hour, .minute], from: now)
        let curH = nowComps.hour ?? 0
        let curM = nowComps.minute ?? 0

        var diffH = hour - curH
        var diffM = min - curM
        if diffM < 0 { diffH -= 1; diffM += 60 }
        if diffH < 0 { diffH += 24 }

        return String(format: "%02d:%02d", diffH, diffM)
    }
}

// MARK: - Large Widget View
struct LargePrayerView: View {
    var entry: SimpleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🕌 أوقات الصلاة")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("اليوم")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }

            Divider().background(Color.white.opacity(0.3))

            ForEach(entry.allPrayers.keys.sorted(by: prayerOrder), id: \.self) { prayer in
                HStack {
                    Text(prayer)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(prayer == entry.upcomingPrayer ? .green : .white)
                    Spacer()
                    Text(entry.allPrayers[prayer] ?? "--:--")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(prayer == entry.upcomingPrayer ? .green : .white.opacity(0.85))
                }
                .padding(.vertical, 3)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(prayer == entry.upcomingPrayer ? Color.green.opacity(0.2) : Color.clear)
                        .shadow(color: prayer == entry.upcomingPrayer ? .green.opacity(0.3) : .clear, radius: 4)
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { prayerGradient }
    }

    func prayerOrder(_ p1: String, _ p2: String) -> Bool {
        let order = ["منتصف الليل", "الثلث الاخير", "الفجر", "الشروق", "الظهر", "العصر", "المغرب", "العشاء"]
        return order.firstIndex(of: p1) ?? 0 < order.firstIndex(of: p2) ?? 0
    }
}

// MARK: - Adaptive Widget View
struct PrayerWidgetView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemLarge:
            LargePrayerView(entry: entry)
        // case .systemMedium:
        //     MediumPrayerView(entry: entry)
        default:
            SmallPrayerView(entry: entry)
        }
    }
}

// MARK: - Main Widget
struct PrayerWidgetExtension: Widget {
    let kind: String = "PrayerWidgetExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PrayerWidgetView(entry: entry)
        }
        .configurationDisplayName("أوقات الصلاة")
        .description("عرض الصلاة القادمة أو جميع الأوقات 🕋")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
