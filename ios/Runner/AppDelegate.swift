import Flutter
import UIKit

private let nativeCrashChannelName = "splunk_sample/native_crash"

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    registerNativeCrashChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func registerNativeCrashChannel() {
    guard let registrar = registrar(forPlugin: "SampleNativeCrash") else { return }
    let channel = FlutterMethodChannel(
      name: nativeCrashChannelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "crash" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(nil)
      // Deferred so the exception escapes this call's stack, producing a
      // real crash instead of an error reply back to Dart.
      DispatchQueue.main.async {
        NSException(
          name: NSExceptionName("Splunk sample crash"),
          reason: "Deferred native crash for crash reporting verification.",
          userInfo: nil
        ).raise()
      }
    }
  }
}
