import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:splunk_sample_app_flutter/data/models.dart';
import 'package:splunk_sample_app_flutter/data/sample_catalog.dart';
import 'package:splunk_sample_app_flutter/demo/demo_controller.dart';
import 'package:splunk_sample_app_flutter/instrumentation/splunk_bridge.dart';
import 'package:splunk_sample_app_flutter/network/demo_network_client.dart';

void main() {
  test(
    'breadcrumb scenario delegates to the instrumentation boundary',
    () async {
      final bridge = _RecordingBridge();
      final network = DemoNetworkClient(
        client: MockClient((_) async => http.Response('', 200)),
        baseUrl: 'https://example.test',
      );
      final controller = DemoController(bridge, network);
      final useCase = sampleCatalog
          .expand((category) => category.useCases)
          .singleWhere((item) => item.action == DemoAction.breadcrumb);

      final result = await controller.run(useCase);

      expect(result.status, DemoStatus.success);
      expect(bridge.breadcrumb, 'flutter-sample');
      network.close();
    },
  );
}

class _RecordingBridge implements InstrumentationBridge {
  String? breadcrumb;

  @override
  bool get isConfigured => true;

  @override
  String get startupMessage => 'Agent started.';

  @override
  http.Client createHttpClient() => http.Client();

  @override
  String excludedUrlConfiguration() => 'Unavailable.';

  @override
  Future<void> leaveBreadcrumb(String value) async => breadcrumb = value;

  @override
  Future<void> reportException(
    Exception exception,
    StackTrace stackTrace,
  ) async {}

  @override
  Future<String> runSessionFrameDemo() async =>
      'Workflow started, and ended.';

  @override
  Future<String> reportCustomData() async => 'Custom data set.';

  @override
  String screenshotConfiguration() => 'Configured.';

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
  Future<String> sessionReplayStatus() async => 'Session replay status: isRecording.';

  @override
  Future<String> toggleSessionReplayMask() async => 'Masking rectangle applied.';
}
