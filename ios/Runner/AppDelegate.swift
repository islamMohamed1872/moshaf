import Flutter
import UIKit
import flutter_background_service_ios
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      SwiftFlutterBackgroundServicePlugin.taskIdentifier = "prayer_times"
      GMSServices.provideAPIKey("AIzaSyBWiuuOH93eV4T8agl0VQszgdBjfIK--Ew")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
