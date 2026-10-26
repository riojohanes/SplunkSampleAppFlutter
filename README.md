# Splunk Sample App for Flutter

A Flutter learning app for Splunk Observability Cloud Mobile RUM on Android and iOS. Browse the same instrumentation scenarios as the native samples, run a demonstration, inspect the Dart snippet, and review the verification steps for Splunk Observability Cloud.

## Requirements

- Flutter 3.32.4 with Dart 3.8.1 (or newer within `splunk_otel_flutter`'s `>=3.32.0`/`>=3.8.0 <4.0.0` floors)
- JDK 17 and Android SDK for Android builds
- Xcode 16 or newer for iOS builds (Swift Package Manager only; this project has no CocoaPods integration)
- `splunk_otel_flutter` 1.2.0 and `splunk_otel_flutter_session_replay` 1.2.0
- A RUM access token and realm from Splunk Observability Cloud

The Splunk Flutter plugin supports Android (API 24+) and iOS (15.0+). This project does not target Flutter web or desktop.

Add the pinned Flutter SDK to your shell when using the local installation created for this project:

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
flutter --version
```

Swift Package Manager must be enabled once per machine for the iOS build:

```bash
flutter config --enable-swift-package-manager
```

## Configure

Create a local configuration file that is ignored by Git:

```bash
cp config/splunk.example.json config/splunk.local.json
```

Set the RUM access token and, if your organization uses a non-default realm, the realm. The application remains usable without credentials and displays an unconfigured-agent status.

Run with the local configuration:

```bash
flutter run --dart-define-from-file=config/splunk.local.json
```

## Splunk integration

| Area | Location |
|---|---|
| Credentials | `config/splunk.local.json`, copied from `config/splunk.example.json` |
| Startup | `lib/main.dart` |
| SDK bridge | `lib/instrumentation/splunk_bridge.dart` |
| Environment values | `lib/config/app_config.dart` |

When `DEMO_BASE_URL` is `http://localhost:8080`, start the local mock API in a
second terminal and keep it running while using the app:

```bash
dart run tool/mock_server.dart
```

For a deterministic local mock server, set `DEMO_BASE_URL`. Android Emulator reaches the Mac host at `http://10.0.2.2:8080`; iOS Simulator uses `http://localhost:8080`; a physical iOS device must use the Mac's LAN address, for example `http://192.168.1.10:8080`. Find the Mac address with `ipconfig getifaddr en0`, put it in `config/splunk.local.json`, and rebuild the app after changing it. The mock server already binds to `0.0.0.0`; keep the phone and Mac on the same network, allow port 8080 through the macOS firewall, and verify the URL in Safari on the phone. This debug app allows local HTTP through iOS App Transport Security; prefer HTTPS for production. The server should expose `/status/200`, `/post`, `/status/404`, `/status/500`, and `/delay/20`.

## Build and test

```bash
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=config/splunk.local.json
flutter build ios --simulator --debug --dart-define-from-file=config/splunk.local.json
```

The Android build enables core-library desugaring and raises `minSdk` to 24, both required by `splunk_otel_flutter`. The iOS build requires Swift Package Manager (`flutter config --enable-swift-package-manager`) and an iOS 15.0+ deployment target, already set in this project.

## Verify instrumentation

Run a scenario and filter the Flutter debug logs for `splunk` or `SplunkRum`. Then allow the normal agent flush interval before checking the corresponding session, network request, custom event, or error in Splunk Observability Cloud's **Sessions** view, **Tag Spotlight**, or RUM dashboards. The app is identified there by the `SPLUNK_APP_NAME`/`SPLUNK_DEPLOYMENT_ENVIRONMENT` values set in your local config.

ANR demonstrations are available only in debug builds. `splunk_otel_flutter` has no API to force a real native process crash from Dart, so the "Crash reporting" demo invokes a small native `MethodChannel` (`android/app/.../MainActivity.kt`, `ios/Runner/AppDelegate.swift`) that raises a real exception outside Dart, captured by `CrashReportsModuleConfiguration`'s native crash handler on the next launch. A debugger attached via `flutter run` intercepts the crash before the handler sees it, so verifying it requires a **profile** build, detaching (`q`), triggering it from the home-screen-launched app, then reopening it — see `docs/splunk-custom-data-and-crash-reporting.md` for the full walkthrough. "Report all crashes (async error)" is a separate, Dart-level path: it throws outside any `try/catch` and is reported via the zone-level error handler.

Network requests made with `package:http` are not confirmed to appear in Splunk's automatic network instrumentation, which wraps native OkHttp/HttpURLConnection (Android) and NSURLSession (iOS) rather than Dart's HTTP stack. The sample documents this and demonstrates the one URL-exclusion mechanism that does exist: `NetworkInstrumentationModuleConfiguration(ignoreURLs:)`, which is iOS-only.

Session replay (`splunk_otel_flutter_session_replay`) records the UI for visual playback in Splunk Observability Cloud's **Sessions** view, separate from the screenshot API this sample's "Periodic screenshots" scenario documents as unavailable in the core SDK. It's enabled via `SessionReplayModuleConfiguration` and started explicitly with `SplunkSessionReplay.instance.start()` — see the "Session Replay" category and `docs/splunk-session-replay.md` for the full walkthrough, including masking sensitive content.

## Project layout

- `lib/config`: compile-time environment configuration
- `lib/data`: scenario catalog, models, and Dart snippet loading
- `lib/demo`: scenario dispatch and debug-only safety gates
- `lib/instrumentation`: the single Splunk SDK boundary
- `lib/network`: HTTP demonstrations
- `lib/ui`: named-route Material interface
- `assets/flutter_snippets.json`: copyable Dart examples
- `test`: catalog, network, controller, and widget tests
