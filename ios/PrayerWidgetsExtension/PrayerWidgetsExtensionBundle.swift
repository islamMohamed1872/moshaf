import WidgetKit
import SwiftUI

@main
struct PrayerWidgetsExtensionBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        PrayerWidgetExtension() // ✅ references the widget defined in the other file
        if #available(iOS 16.1, *) {
            PrayerLiveActivity() // ✅ new live activity
        }
    }
}
