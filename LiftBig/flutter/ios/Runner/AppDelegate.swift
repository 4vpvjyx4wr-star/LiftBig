import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    CompanionBridge.shared.start()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    RestNotificationStopBridge.install()
    let messenger = engineBridge.applicationRegistrar.messenger()
    CompanionBridge.shared.register(messenger: messenger)
    RestAlarmPlayer.register(messenger: messenger)
    ProBridge.shared.register(messenger: messenger)
    registerGoogleSignInConfig(messenger: messenger)
  }

  private func registerGoogleSignInConfig(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "liftbig/google_sign_in", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      if call.method == "configuration" {
        result(Self.googleSignInConfiguration())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// True only when a reversed Google client id is registered as a URL scheme.
  /// An empty scheme makes GIDSignIn raise an NSException that Dart cannot catch.
  static func googleSignInConfiguration() -> [String: Any] {
    let types = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] ?? []
    let schemes = types.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
    let ready = schemes.contains { scheme in
      !scheme.isEmpty && scheme.hasPrefix("com.googleusercontent.apps.")
    }
    var payload: [String: Any] = ["ready": ready]
    if let server = Bundle.main.object(forInfoDictionaryKey: "GIDServerClientID") as? String,
       server.contains(".apps.googleusercontent.com") {
      payload["serverClientId"] = server
    }
    return payload
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if CompanionBridge.shared.open(url: url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }

}
