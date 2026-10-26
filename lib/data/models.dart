enum DemoAction {
  appStart,
  viewTransition,
  sessionFrame,
  startNextSession,
  breadcrumb,
  customData,
  periodicScreenshots,
  networkSuccess,
  networkPost,
  excludedUrls,
  network404,
  network500,
  networkTimeout,
  reportError,
  anr,
  crash,
  reportAllCrashes,
  sessionReplayStatus,
  sessionReplayMask,
}

class UseCase {
  const UseCase({
    required this.name,
    required this.prompt,
    required this.action,
    required this.snippetKey,
  });

  final String name;
  final String prompt;
  final DemoAction action;
  final String snippetKey;

  String get nextSteps =>
      'Check the Flutter debug console for Splunk RUM output, then inspect '
      'the matching event in Splunk Observability Cloud. Telemetry flushes '
      'periodically, so allow a short delay.';
}

class Category {
  const Category({
    required this.name,
    required this.caption,
    required this.useCases,
  });

  final String name;
  final String caption;
  final List<UseCase> useCases;
}

enum DemoStatus { success, failure }

class DemoResult {
  const DemoResult(this.status, this.message);

  final DemoStatus status;
  final String message;
}
