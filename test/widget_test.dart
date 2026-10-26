import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:splunk_sample_app_flutter/config/app_config.dart';
import 'package:splunk_sample_app_flutter/instrumentation/splunk_bridge.dart';
import 'package:splunk_sample_app_flutter/ui/sample_app.dart';

void main() {
  testWidgets('opens a learning category', (tester) async {
    await tester.pumpWidget(
      SampleApp(
        config: const AppConfig(
          rumAccessToken: '',
          realm: 'us0',
          appName: 'splunk-sample-app-flutter',
          deploymentEnvironment: 'development',
          demoBaseUrl: 'https://httpbin.org',
        ),
        bridge: _FakeBridge(),
      ),
    );

    expect(find.text('Features'), findsOneWidget);
    expect(find.text('Networking'), findsOneWidget);
    expect(find.text('Error Conditions'), findsOneWidget);

    await tester.tap(find.byKey(const Key('category-Features')));
    await tester.pumpAndSettle();

    expect(find.text('Start app'), findsOneWidget);
    expect(find.text('Screen transition tracking'), findsOneWidget);
  });
}

class _FakeBridge implements InstrumentationBridge {
  @override
  bool get isConfigured => false;

  @override
  String get startupMessage => 'Splunk RUM is not configured.';

  @override
  http.Client createHttpClient() => http.Client();

  @override
  String excludedUrlConfiguration() => 'URL exclusions are unavailable.';

  @override
  Future<void> leaveBreadcrumb(String value) async {}

  @override
  Future<void> reportException(
    Exception exception,
    StackTrace stackTrace,
  ) async {}

  @override
  Future<String> runSessionFrameDemo() async =>
      'Agent not configured; no workflow was sent.';

  @override
  Future<String> reportCustomData() async =>
      'Agent not configured; no custom data was sent.';

  @override
  String screenshotConfiguration() => 'Agent not configured.';

  @override
  Future<void> startNextSession() async {}

  @override
  Future<void> takeScreenshot() async {}

  @override
  Future<void> triggerAnr() async {}

  @override
  Future<void> triggerCrash() async {}

  @override
  Future<void> triggerUnhandledAsyncError() async {}

  @override
  Future<void> reportZoneError(Object error, StackTrace stackTrace) async {}

  @override
  Future<String> sessionReplayStatus() async =>
      'Agent not configured; session replay is unavailable.';

  @override
  Future<String> toggleSessionReplayMask() async =>
      'Agent not configured; no mask was applied.';
}
