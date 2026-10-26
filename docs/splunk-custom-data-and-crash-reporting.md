# Splunk on Flutter: Global Attributes and Error Reporting

This guide shows how to add two Splunk Observability Cloud Mobile RUM features to a Flutter app:

1. **Global attributes**: attach your own key/value data to all telemetry sent afterward.
2. **Error reporting**: report caught Dart exceptions, uncaught Flutter framework errors, and uncaught async Dart errors.

Everything here was verified against `splunk_otel_flutter: 1.2.0`'s installed source. The working reference is this sample app. See [Reference files](#reference-files).

Official docs:
- [Install the Splunk RUM Flutter agent](https://help.splunk.com/en/splunk-observability-cloud/manage-data/available-data-sources/supported-integrations-in-splunk-observability-cloud/rum-instrumentation/instrument-mobile-and-web-applications-for-splunk-real-user-monitoring-rum/instrument-flutter-applications-for-splunk-rum/install-the-splunk-rum-flutter-agent)
- [Introduction to Splunk RUM](https://help.splunk.com/en/splunk-observability-cloud/monitor-end-user-experience/real-user-monitoring/introduction-to-splunk-rum)

---

## Prerequisites

- The `splunk_otel_flutter` package is in `pubspec.yaml`:
  ```yaml
  dependencies:
    splunk_otel_flutter: ^1.2.0
  ```
- The agent is started with `SplunkRum.instance.install(...)` before you use any of the APIs below.
- You have a RUM access token and realm from Splunk Observability Cloud.

---

## Part 1: Global attributes

### What it is

Global attributes are key/value pairs that attach to every span and event the agent sends afterward. Use them for things like the user's plan tier, a feature flag, or a retry count.

> **Where to look in Splunk Observability Cloud:** global attributes appear as attributes on spans in **Tag Spotlight** and in the session's trace waterfall, not on a dedicated "custom data" page.

### API

| Type     | Set                                                      |
|----------|-----------------------------------------------------------|
| `String` | `SplunkRum.instance.globalAttributes.setString(key:, value:)` |
| `int`    | `SplunkRum.instance.globalAttributes.setInt(key:, value:)`     |
| `double` | `SplunkRum.instance.globalAttributes.setDouble(key:, value:)`  |
| `bool`   | `SplunkRum.instance.globalAttributes.setBool(key:, value:)`    |

Other operations: `get(key:)`, `getAll()`, `remove(key:)`, `removeAll()`, `contains(key:)`, `setAll(attributes:)`.

Rules:
- Setting the same key again overwrites the old value.
- Attributes are process-lifetime state; they are not guaranteed to persist across process death, so set them again on every launch (for example, right after login).

### Example

```dart
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

Future<void> tagSession(User user) async {
  final attributes = SplunkRum.instance.globalAttributes;
  await attributes.setString(key: 'user.tier', value: user.tier);
  await attributes.setInt(key: 'cart_items', value: user.cartCount);
  await attributes.setBool(key: 'premium', value: user.isPremium);
}
```

> Do not put personal data (names, emails, phone numbers, tokens) in global attributes. Use IDs or categories instead.

---

## Part 2: Error reporting

Unlike AppDynamics, `splunk_otel_flutter` has no app-facing API to force a real native process crash from Dart. There is no Dart equivalent of `Instrumentation.crash()`. Native process crashes are instead captured automatically by `CrashReportsModuleConfiguration`, the same way a native Android/iOS app's own crashes are captured — nothing to wire up manually for *organic* crashes. To deliberately *trigger* one for testing, this sample adds a small native `MethodChannel` (see Step 4) that raises a real exception outside Dart, which the same crash handler then captures.

What you can do manually is report Dart-level errors as RUM error spans, or trigger a real native crash via the native channel:

| Failure type                                 | How it's reported                                             |
|-----------------------------------------------|-----------------------------------------------------------------|
| A caught Dart exception (inside `catch`)      | `customTracking.trackError(error, stackTrace:, handled: true)`  |
| Flutter framework error (build/layout/paint)  | `FlutterError.onError` → `trackError(..., handled: false)`      |
| Uncaught async Dart error (Futures, timers)   | `runZonedGuarded` error callback → `trackError(..., handled: false)` |
| Native process crash (organic)                | Automatic via `CrashReportsModuleConfiguration` (no manual code) |
| Native process crash (deliberately triggered) | Native `MethodChannel` (`splunk_sample/native_crash`) raises a real exception; captured by the same handler |

### Step 1: Enable the crash reports module

```dart
await SplunkRum.instance.install(
  agentConfiguration: AgentConfiguration(
    endpoint: EndpointConfiguration.forRum(realm: realm, rumAccessToken: token),
    appName: appName,
    deploymentEnvironment: deploymentEnvironment,
  ),
  moduleConfigurations: [
    CrashReportsModuleConfiguration(),
    // ...other modules
  ],
);
```

### Step 2: Wrap the whole app in `runZonedGuarded` and wire `FlutterError.onError`

```dart
void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized(); // must be INSIDE the zone
      await startSplunkRum();                     // Step 1
      runApp(const MyApp());
    },
    (error, stackTrace) {
      SplunkRum.instance.customTracking.trackError(
        error,
        stackTrace: stackTrace,
        handled: false,
        source: ErrorSource.source,
      );
    },
  );
}
```

> **Common mistake:** calling `WidgetsFlutterBinding.ensureInitialized()` *outside* the zone and `runApp` *inside* it. In debug builds Flutter then logs a "Zone mismatch" warning. Keep both inside the same zone, as shown above.

### Step 3: Report caught errors at the call site

```dart
try {
  await riskyOperation();
} catch (error, stackTrace) {
  await SplunkRum.instance.customTracking.trackError(
    error,
    stackTrace: stackTrace,
    handled: true,
  );
}
```

`trackError` never throws and always completes, even if the bridge is unavailable, so it's safe to call from any error handler.

### Step 4: Trigger a real native crash for testing

Because there is no Dart-level trigger for a genuine native process crash, this sample adds a small channel in both `android/app/.../MainActivity.kt` and `ios/Runner/AppDelegate.swift`. Each replies to the call first, then raises the real exception on the next turn of the main run loop, outside the method channel's own call stack:

```kotlin
// MainActivity.kt
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "splunk_sample/native_crash")
  .setMethodCallHandler { call, result ->
    if (call.method != "crash") { result.notImplemented(); return@setMethodCallHandler }
    result.success(null)
    Handler(Looper.getMainLooper()).post {
      throw RuntimeException("Deliberate native crash for crash reporting verification.")
    }
  }
```

```swift
// AppDelegate.swift
let channel = FlutterMethodChannel(name: "splunk_sample/native_crash", binaryMessenger: registrar.messenger())
channel.setMethodCallHandler { call, result in
  guard call.method == "crash" else { result(FlutterMethodNotImplemented); return }
  result(nil)
  DispatchQueue.main.async {
    NSException(name: NSExceptionName("Splunk sample crash"), reason: "...", userInfo: nil).raise()
  }
}
```

On the Dart side:

```dart
const _nativeCrashChannel = MethodChannel('splunk_sample/native_crash');

Future<void> triggerCrash() async {
  await _nativeCrashChannel.invokeMethod<void>('crash');
}
```

> Only expose test-crash buttons in debug/profile builds (guard with `if (kReleaseMode) return;`, which `lib/demo/demo_controller.dart` already does). Never ship them in a release build.

The adjacent "Report all crashes (async error)" demo throws from a `Future.microtask` outside any `try/catch`, which is caught by the `runZonedGuarded` handler from Step 2 and reaches Splunk Observability Cloud as an error span — a different, Dart-level path from the native crash above, useful for comparison.

---

## How to verify

### Global attributes

1. Set a global attribute (Part 1).
2. In the same app session, run a demo that produces a span (a network request, a workflow, a custom event, or the async-error demo).
3. Wait a few minutes for data to upload.
4. Open **Tag Spotlight** in Splunk Observability Cloud, filter by the app/environment, and check that the attribute appears on spans created after it was set.

### Error reporting

1. Run "Report error" (a caught exception, reported with `handled: true`) or "Report all crashes (async error)" (uncaught, reported with `handled: false`).
2. Wait for the normal agent flush interval.
3. Open the session in **Sessions** and look for the error span, or check error-related views in RUM dashboards.

### Native crash

The debugger intercepts crashes while `flutter run` is attached, so the agent cannot record them during a normal debug session. Test with a **profile** build instead:

1. `flutter run --profile --dart-define-from-file=config/splunk.local.json`
2. Once the app launches, press `q` to quit `flutter run`. The app stays installed.
3. Open the app **from the home screen**, go to Error Conditions → "Crash reporting", and run the demonstration. The app should close immediately.
4. Open the app again from the home screen and keep it open for about a minute. The crash report uploads on this launch.
5. After a few minutes, check Splunk Observability Cloud for the uploaded crash.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| "Crash reporting" doesn't crash the app | Running a debug build with `flutter run` attached, or a release build | Use a profile build and detach (`q`) before triggering it; release builds are blocked by `kReleaseMode` in `demo_controller.dart` |
| App crashes but nothing shows in Splunk Observability Cloud | Debugger was attached, or the app wasn't reopened afterward | Use a profile build, launch from the home screen, then reopen after the crash so the report can upload |
| "Zone mismatch" warning in the console | `ensureInitialized()` and `runApp()` run in different zones | Move both inside `runZonedGuarded` |
| Nothing at all reaches Splunk Observability Cloud | Wrong RUM access token/realm, or no network | Check that `install()` completed without throwing and the device can reach the configured realm |
| Build fails on Android | `minSdkVersion` below 24, or desugaring not enabled | See `android/app/build.gradle.kts` in this sample |

---

## Reference files

In this sample app:

- `lib/main.dart`: `runZonedGuarded` setup
- `lib/instrumentation/splunk_bridge.dart`: agent config, module configuration, error handlers, `reportCustomData()`, `triggerCrash()`
- `android/app/src/main/kotlin/.../MainActivity.kt`: Android native crash channel
- `ios/Runner/AppDelegate.swift`: iOS native crash channel
- `lib/demo/demo_controller.dart`: how the demo screens call these features
