import Flutter
import UIKit
import flutter_background_service_ios
import GoogleMaps
import ActivityKit
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      SwiftFlutterBackgroundServicePlugin.taskIdentifier = "prayer_times"
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
            GMSServices.provideAPIKey(apiKey)
        }
           GeneratedPluginRegistrant.register(with: self)
      let controller = window?.rootViewController as! FlutterViewController
      if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
      }
      // let channel = FlutterMethodChannel(name: "mostakeem/live_activity", binaryMessenger: controller.binaryMessenger)
      // channel.setMethodCallHandler { call, result in
      //     if #available(iOS 16.1, *) {
      //         switch call.method {
      //         case "startActivity":
      //             guard let args = call.arguments as? [String: Any],
      //                   let upcoming = args["upcomingPrayer"] as? String,
      //                   let remaining = args["remaining"] as? Double,
      //                   let upcomingTime = args["upcomingTime"] as? String else { return }
      //             let attr = PrayerActivityAttributes(location: "القاهرة")
      //             let content = PrayerActivityAttributes.ContentState(
      //                 upcomingPrayer: upcoming,
      //                 remainingTime: remaining,
      //                 upcomingTime: upcomingTime
      //             )
      //             do {
      //                 _ = try Activity<PrayerActivityAttributes>.request(
      //                     attributes: attr,
      //                     contentState: content,
      //                     pushType: nil
      //                 )
      //                 result("started")
      //             } catch {
      //                 result(FlutterError(code: "START_FAIL", message: "\(error)", details: nil))
      //             }
      //
      //         case "updateActivity":
      //             guard let args = call.arguments as? [String: Any],
      //                   let remaining = args["remaining"] as? Double else { return }
      //             Task {
      //                 for activity in Activity<PrayerActivityAttributes>.activities {
      //                     await activity.update(using: .init(
      //                         upcomingPrayer: activity.contentState.upcomingPrayer,
      //                         remainingTime: remaining,
      //                         upcomingTime: activity.contentState.upcomingTime
      //                     ))
      //                 }
      //             }
      //             result("updated")
      //
      //         case "endActivity":
      //             Task {
      //                 for activity in Activity<PrayerActivityAttributes>.activities {
      //                     await activity.end(dismissalPolicy: .immediate)
      //                 }
      //             }
      //             result("ended")
      //         default:
      //             result(FlutterMethodNotImplemented)
      //         }
      //     } else {
      //         result("Not supported")
      //     }
      // }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
