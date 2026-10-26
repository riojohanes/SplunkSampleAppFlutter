# Splunk on Flutter: Session Replay

This guide shows how to add visual session replay to a Flutter app using Splunk Observability Cloud Mobile RUM.

Everything here was verified against `splunk_otel_flutter_session_replay: 1.2.0`'s installed source. The working reference is this sample app. See [Reference files](#reference-files).

Official docs:
- [Record Android sessions](https://help.splunk.com/en/splunk-observability-cloud/monitor-end-user-experience/real-user-monitoring/replay-user-sessions/record-android-sessions)
- [Introduction to Splunk RUM](https://help.splunk.com/en/splunk-observability-cloud/monitor-end-user-experience/real-user-monitoring/introduction-to-splunk-rum)

---

## Prerequisites

- Both packages are in `pubspec.yaml`:
  ```yaml
  dependencies:
    splunk_otel_flutter: ^1.2.0
    splunk_otel_flutter_session_replay: ^1.2.0
  ```
- Platform setup (Android `minSdk 24` + core-library desugaring, iOS Swift Package Manager + 15.0 deployment target) is identical to the core SDK — this sample already has it configured.
- `splunk_otel_flutter_session_replay` is an add-on: `SessionReplayModuleConfiguration` is exported from the *core* `splunk_otel_flutter` package and does nothing on its own until this add-on package is also installed.

---

## What it is

Session replay records the app's UI so a session can be watched back visually in Splunk Observability Cloud, alongside its spans and errors. It's enabled per-install via a module configuration, then started/stopped at runtime through a separate `SplunkSessionReplay` singleton — enabling the module does **not** start recording by itself.

---

## Step 1: Enable the module at install time

```dart
await SplunkRum.instance.install(
  agentConfiguration: AgentConfiguration(
    endpoint: EndpointConfiguration.forRum(realm: realm, rumAccessToken: token),
    appName: appName,
    deploymentEnvironment: deploymentEnvironment,
  ),
  moduleConfigurations: [
    // ...other modules
    SessionReplayModuleConfiguration(samplingRate: 1.0),
  ],
);
```

`samplingRate` is clamped to `[0.0, 1.0]` and defaults to `0.2` (20% of sessions) if omitted. This sample uses `1.0` so the demo always records, rather than randomly sampling out — tune this down for production use to control recording volume/cost.

## Step 2: Start recording

```dart
await SplunkSessionReplay.instance.start();
```

Call this once, right after `install()` succeeds (see `SplunkBridge.initialize()` in this sample). There's also a matching `SplunkSessionReplay.instance.stop()`.

## Step 3: Check recording status

```dart
final status = await SplunkSessionReplay.instance.getStatus();
```

`status` is a `SessionReplayStatus`: `isRecording`, `notStarted`, `stopped`, `belowMinSdkVersion`, `storageLimitReached`, `internalError`, or `disabledBySampling`. If you see `disabledBySampling` even with `samplingRate: 1.0`, check that `install()` actually succeeded (bad credentials fail silently into an unconfigured state in this sample, surfaced via the home screen's status banner).

## Step 4: Mask sensitive content

Cover or erase rectangular regions so they never appear in the recording:

```dart
await SplunkSessionReplay.instance.setRecordingMask(
  mask: RecordingMask(
    elements: [
      MaskElement(
        rect: const Rect.fromLTWH(0, 0, 200, 80),
        type: MaskType.covering, // or MaskType.erasing
      ),
    ],
  ),
);

// Clear the mask when it's no longer needed.
await SplunkSessionReplay.instance.setRecordingMask(mask: null);
```

`getRecordingMask()` reads back the currently applied mask (or `null`). `MaskType.covering` overlays the region with a solid color; `MaskType.erasing` removes it from the recording entirely. This sample's mask rectangle is a fixed illustrative region, not computed from any real widget's position — in a production app, you'd typically compute `rect` from a `RenderBox` you want to hide (a password field, a credit card number, etc.).

---

## How to verify

1. Launch the app with real credentials (`config/splunk.local.json`) and confirm the status banner reads "Splunk RUM Flutter agent started."
2. Open Session Replay → "Recording status" and confirm it reports `isRecording`.
3. Navigate around the app a bit (open a few categories/demos) so there's meaningful screen content to record.
4. Open Session Replay → "Mask sensitive content" once or twice to see the message toggle between applied/cleared.
5. Wait for the normal ingest delay, then open the session in Splunk Observability Cloud's **Sessions** view — there should be a replay/recording available to watch back for that session.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Status is always `notStarted` | `SplunkSessionReplay.instance.start()` was never called | The module configuration alone doesn't start recording — call `start()` explicitly (see Step 2) |
| Status is `disabledBySampling` despite `samplingRate: 1.0` | The agent never actually installed (bad token/realm) | Check the home screen's status banner for an install failure message |
| Status is `belowMinSdkVersion` | Device is below Android API 24 | Not supported; this matches the core SDK's own floor |
| No replay appears in Splunk Observability Cloud | Normal ingest delay, or session too short to have any recorded frames | Wait a few minutes; navigate around the app more before checking |
| Replay shows the previous screen for ~15s after navigating before catching up, even with `isRecording` confirmed on a physical device | Likely an inherent capture-cadence limitation, not a code or config issue: `SessionReplayModuleConfiguration`/`SplunkSessionReplay` expose no interval or "capture now" API, and a Flutter app renders as one opaque `FlutterView` surface, which native view-transition-triggered capture (used by native Android/iOS apps) can't hook into the same way | No app-level fix available in `splunk_otel_flutter_session_replay` 1.2.0; if this matters for your use case, report it to Splunk via the [`signalfx/splunk-otel-flutter` GitHub issues](https://github.com/signalfx/splunk-otel-flutter/issues) |

---

## Reference files

In this sample app:

- `lib/instrumentation/splunk_bridge.dart`: module configuration, `start()`, `sessionReplayStatus()`, `toggleSessionReplayMask()`
- `lib/data/sample_catalog.dart`: the "Session Replay" category
- `lib/demo/demo_controller.dart`: how the demo screens call these features
