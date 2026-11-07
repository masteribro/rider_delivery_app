import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Load API key from .env (Flutter asset bundle)
    var envContents: String? = nil

    // Flutter assets are stored inside App.framework/flutter_assets/
    if let resourcePath = Bundle.main.resourcePath {
      let flutterEnvPath = resourcePath + "/Frameworks/App.framework/flutter_assets/.env"
      envContents = try? String(contentsOfFile: flutterEnvPath, encoding: .utf8)
    }

    // Fallback: check native bundle root
    if envContents == nil, let path = Bundle.main.path(forResource: ".env", ofType: nil) {
      envContents = try? String(contentsOfFile: path, encoding: .utf8)
    }

    if let contents = envContents {
      for line in contents.components(separatedBy: "\n") {
        let parts = line.components(separatedBy: "=")
        if parts.count == 2 && parts[0].trimmingCharacters(in: .whitespaces) == "GOOGLE_MAPS_API_KEY" {
          GMSServices.provideAPIKey(parts[1].trimmingCharacters(in: .whitespacesAndNewlines))
        }
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
