import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_session_replay/splunk_otel_flutter_session_replay.dart';

import '../config/app_config.dart';

const _nativeCrashChannel = MethodChannel('splunk_sample/native_crash');

abstract class InstrumentationBridge {
  bool get isConfigured;
  String get startupMessage;
  http.Client createHttpClient();
  Future<void> startNextSession();
  Future<void> leaveBreadcrumb(String value);
  Future<String> runSessionFrameDemo();
  Future<String> reportCustomData();
  Future<void> takeScreenshot();
  Future<void> reportException(Exception exception, StackTrace stackTrace);
  Future<void> triggerAnr();
  Future<void> triggerCrash();
  Future<void> triggerUnhandledAsyncError();
  Future<void> reportZoneError(Object error, StackTrace stackTrace);
  String screenshotConfiguration();
  String excludedUrlConfiguration();
  Future<String> sessionReplayStatus();
  Future<String> toggleSessionReplayMask();
}

class SplunkBridge implements InstrumentationBridge {
  SplunkBridge(this.config);

  final AppConfig config;
  bool _isConfigured = false;
  String _startupMessage = 'Splunk RUM has not been initialized.';
  bool _maskApplied = false;

  @override
  bool get isConfigured => _isConfigured;

  @override
  String get startupMessage => _startupMessage;

  Future<void> initialize() async {
    if (config.rumAccessToken.trim().isEmpty) {
      _startupMessage =
          'Splunk RUM is not configured. Add SPLUNK_RUM_ACCESS_TOKEN with --dart-define.';
      return;
    }

    try {
      await SplunkRum.instance.install(
        agentConfiguration: AgentConfiguration(
          endpoint: EndpointConfiguration.forRum(
            realm: config.realm,
            rumAccessToken: config.rumAccessToken,
          ),
          appName: config.appName,
          deploymentEnvironment: config.deploymentEnvironment,
          enableDebugLogging: kDebugMode,
        ),
        moduleConfigurations: [
          CrashReportsModuleConfiguration(),
          NavigationModuleConfiguration(),
          NetworkMonitorModuleConfiguration(),
          SlowRenderingModuleConfiguration(),
          AnrModuleConfiguration(),
          // samplingRate: 1.0 (not the SDK's 0.2 default) so this demo app
          // always records, rather than randomly sampling out.
          SessionReplayModuleConfiguration(samplingRate: 1.0),
        ],
      );
      _isConfigured = true;
      _startupMessage = 'Splunk RUM Flutter agent started.';
      // The module configuration only enables session replay; recording
      // itself must be started explicitly.
      await SplunkSessionReplay.instance.start();
    } on Exception catch (error) {
      _startupMessage = 'Splunk RUM failed to start: $error';
    }
  }

  // No Dart-level equivalent of AppDynamics' TrackedHttpClient is documented
  // for splunk_otel_flutter 1.2.0: automatic network instrumentation wraps
  // native OkHttp/HttpURLConnection (Android) and NSURLSession (iOS), not
  // Dart's package:http. Visibility of these calls in RUM is unconfirmed.
  @override
  http.Client createHttpClient() => http.Client();

  // No manual session-rollover API is exposed; SplunkRum.instance.session
  // only exposes read-only state (getId/getSamplingRate).
  @override
  Future<void> startNextSession() async {}

  @override
  Future<void> leaveBreadcrumb(String value) async {
    if (_isConfigured) {
      await SplunkRum.instance.customTracking.trackCustomEvent(
        name: 'breadcrumb',
        attributes: MutableAttributes(
          attributes: {'value': MutableAttributeString(value: value)},
        ),
      );
    }
  }

  @override
  Future<String> runSessionFrameDemo() async {
    if (!_isConfigured) {
      return 'Agent not configured; no workflow was sent.';
    }

    final workflow = await SplunkRum.instance.customTracking.startWorkflow(
      name: 'Journey Map Demo',
    );
    await workflow.end();
    return 'Workflow "Journey Map Demo" started and ended. Splunk has no '
        'renameable per-step label like AppDynamics\' SessionFrame; a '
        'workflow span is the closest analog for labeling a step.';
  }

  @override
  Future<String> reportCustomData() async {
    if (!_isConfigured) {
      return 'Agent not configured; no custom data was sent.';
    }

    final attributes = SplunkRum.instance.globalAttributes;
    await attributes.setString(key: 'sample_user_tier', value: 'gold');
    await attributes.setInt(key: 'sample_retry_count', value: 3);
    await attributes.setBool(key: 'sample_premium_feature', value: true);
    return 'Global attributes set (sample_user_tier, sample_retry_count, '
        'sample_premium_feature). These attach to all telemetry sent from '
        'this point forward; check Tag Spotlight or a span\'s attributes.';
  }

  // There is still no single-shot "take a screenshot" API; the core RUM SDK
  // only offers continuous recording via the splunk_otel_flutter_session_replay
  // add-on (see sessionReplayStatus()/toggleSessionReplayMask() below), which
  // is a different capability from a point-in-time screenshot.
  @override
  Future<void> takeScreenshot() async {}

  @override
  Future<void> reportException(
    Exception exception,
    StackTrace stackTrace,
  ) async {
    if (_isConfigured) {
      await SplunkRum.instance.customTracking.trackError(
        exception,
        stackTrace: stackTrace,
        handled: true,
      );
    }
  }

  @override
  Future<void> triggerAnr() async {
    // splunk_otel_flutter has no manual ANR trigger; block the engine thread
    // directly so the native ANR/app-hang watchdog (AnrModuleConfiguration,
    // Android) can detect it, mirroring AppDynamics' Instrumentation.sleep.
    sleep(const Duration(seconds: 6));
  }

  @override
  Future<void> triggerCrash() async {
    // splunk_otel_flutter has no Dart-level API to force a native process
    // crash, so this invokes a small native MethodChannel (Android:
    // MainActivity.kt, iOS: AppDelegate.swift) that raises a real exception
    // outside Dart. CrashReportsModuleConfiguration's native crash handler
    // captures it and uploads the report on the next app launch.
    await _nativeCrashChannel.invokeMethod<void>('crash');
  }

  @override
  Future<void> triggerUnhandledAsyncError() async {
    Future.microtask(() {
      throw StateError(
        'Unhandled async error outside try/catch (debug-only).',
      );
    });
  }

  @override
  Future<void> reportZoneError(Object error, StackTrace stackTrace) async {
    if (_isConfigured) {
      await SplunkRum.instance.customTracking.trackError(
        error,
        stackTrace: stackTrace,
        handled: false,
        source: ErrorSource.source,
      );
    }
  }

  @override
  String screenshotConfiguration() =>
      'There is no single-shot screenshot API; see the Session Replay '
      'category for continuous recording via splunk_otel_flutter_session_replay.';

  @override
  Future<String> sessionReplayStatus() async {
    if (!_isConfigured) {
      return 'Agent not configured; session replay is unavailable.';
    }

    final status = await SplunkSessionReplay.instance.getStatus();
    return 'Session replay status: ${status.name}.';
  }

  @override
  Future<String> toggleSessionReplayMask() async {
    if (!_isConfigured) {
      return 'Agent not configured; no mask was applied.';
    }

    if (_maskApplied) {
      await SplunkSessionReplay.instance.setRecordingMask(mask: null);
      _maskApplied = false;
      return 'Masking rectangle cleared.';
    }

    // An illustrative fixed region, not computed from any real widget's
    // RenderBox -- just enough to demonstrate the API.
    await SplunkSessionReplay.instance.setRecordingMask(
      mask: RecordingMask(
        elements: [
          MaskElement(
            rect: const Rect.fromLTWH(0, 0, 200, 80),
            type: MaskType.covering,
          ),
        ],
      ),
    );
    _maskApplied = true;
    return 'Masking rectangle applied -- this region will be covered in '
        'the replay.';
  }

  @override
  String excludedUrlConfiguration() =>
      'On iOS, NetworkInstrumentationModuleConfiguration(ignoreURLs: [...]) '
      'excludes matching URLs from tracing. Android has no URL-exclusion API '
      'exposed by splunk_otel_flutter 1.2.0; use a plain http.Client for calls '
      'that must remain untracked there.';
}
