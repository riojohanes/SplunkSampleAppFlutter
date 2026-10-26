import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../instrumentation/splunk_bridge.dart';
import '../network/demo_network_client.dart';

class DemoController {
  DemoController(this.bridge, this.networkClient);

  final InstrumentationBridge bridge;
  final DemoNetworkClient networkClient;

  Future<DemoResult> run(UseCase useCase) async {
    switch (useCase.action) {
      case DemoAction.appStart:
        return DemoResult(DemoStatus.success, bridge.startupMessage);
      case DemoAction.viewTransition:
        return const DemoResult(
          DemoStatus.success,
          'Named-route navigation completed; inspect the screen event.',
        );
      case DemoAction.sessionFrame:
        final message = await bridge.runSessionFrameDemo();
        return DemoResult(DemoStatus.success, message);
      case DemoAction.startNextSession:
        await bridge.startNextSession();
        return DemoResult(
          DemoStatus.success,
          bridge.isConfigured
              ? 'New session requested.'
              : 'Agent not configured; no session event was sent.',
        );
      case DemoAction.breadcrumb:
        await bridge.leaveBreadcrumb('flutter-sample');
        return DemoResult(
          DemoStatus.success,
          bridge.isConfigured
              ? 'Breadcrumb flutter-sample created.'
              : 'Agent not configured; no breadcrumb was sent.',
        );
      case DemoAction.customData:
        final message = await bridge.reportCustomData();
        return DemoResult(DemoStatus.success, message);
      case DemoAction.periodicScreenshots:
        await bridge.takeScreenshot();
        return DemoResult(DemoStatus.success, bridge.screenshotConfiguration());
      case DemoAction.excludedUrls:
        return DemoResult(
          DemoStatus.success,
          bridge.excludedUrlConfiguration(),
        );
      case DemoAction.networkSuccess:
      case DemoAction.networkPost:
      case DemoAction.network404:
      case DemoAction.network500:
      case DemoAction.networkTimeout:
        return networkClient.execute(useCase.action);
      case DemoAction.reportError:
        final exception = Exception('Controlled Splunk sample error');
        await bridge.reportException(exception, StackTrace.current);
        return DemoResult(
          DemoStatus.success,
          bridge.isConfigured
              ? 'Controlled exception reported.'
              : 'Agent not configured; no exception was sent.',
        );
      case DemoAction.anr:
        if (!kDebugMode) {
          return const DemoResult(
            DemoStatus.failure,
            'ANR demonstrations are disabled outside debug builds.',
          );
        }
        await bridge.triggerAnr();
        return const DemoResult(
          DemoStatus.success,
          'Native main thread recovered after the debug-only sleep.',
        );
      case DemoAction.crash:
        if (kReleaseMode) {
          return const DemoResult(
            DemoStatus.failure,
            'Crash demonstrations are disabled in release builds.',
          );
        }
        await bridge.triggerCrash();
        return const DemoResult(DemoStatus.success, 'Native crash requested.');
      case DemoAction.reportAllCrashes:
        if (!kDebugMode) {
          return const DemoResult(
            DemoStatus.failure,
            'This demonstration is disabled outside debug builds.',
          );
        }
        await bridge.triggerUnhandledAsyncError();
        return const DemoResult(
          DemoStatus.success,
          'Unhandled async error thrown. Check the debug console and '
          'Splunk Observability Cloud for the reported error.',
        );
      case DemoAction.sessionReplayStatus:
        final message = await bridge.sessionReplayStatus();
        return DemoResult(DemoStatus.success, message);
      case DemoAction.sessionReplayMask:
        final message = await bridge.toggleSessionReplayMask();
        return DemoResult(DemoStatus.success, message);
    }
  }
}
