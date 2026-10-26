import 'models.dart';

const sampleCatalog = <Category>[
  Category(
    name: 'Features',
    caption:
        'Instrument everyday interactions and learn which capabilities work automatically.',
    useCases: [
      UseCase(
        name: 'Start app',
        prompt: 'Initialize the Splunk RUM agent before Flutter renders.',
        action: DemoAction.appStart,
        snippetKey: 'App Start',
      ),
      UseCase(
        name: 'Screen transition tracking',
        prompt: 'Navigate between named routes and inspect screen events.',
        action: DemoAction.viewTransition,
        snippetKey: 'Screen transition tracking',
      ),
      UseCase(
        name: 'Workflow custom label',
        prompt:
            'Splunk has no renameable per-step label like AppDynamics\' '
            'SessionFrame; a named workflow span is the closest analog for '
            'labeling a step.',
        action: DemoAction.sessionFrame,
        snippetKey: 'Workflow label (SessionFrame equivalent)',
      ),
      UseCase(
        name: 'Start next session',
        prompt: 'Attempt to roll over to a new RUM session.',
        action: DemoAction.startNextSession,
        snippetKey: 'Start next session',
      ),
      UseCase(
        name: 'Breadcrumb',
        prompt:
            'Leave a breadcrumb-style custom event that appears alongside '
            'other session telemetry.',
        action: DemoAction.breadcrumb,
        snippetKey: 'Leaving a breadcrumb',
      ),
      UseCase(
        name: 'Custom data (global attributes)',
        prompt:
            'Attach global attributes that are included on all telemetry '
            'sent afterward; inspect them in Tag Spotlight or on any span.',
        action: DemoAction.customData,
        snippetKey: 'Custom data (global attributes)',
      ),
      UseCase(
        name: 'Periodic screenshots',
        prompt:
            'Attempt a screenshot capture; the core RUM SDK has no such API '
            '(that belongs to the separate session-replay add-on).',
        action: DemoAction.periodicScreenshots,
        snippetKey: 'Periodic screenshots',
      ),
    ],
  ),
  Category(
    name: 'Networking',
    caption:
        'Exercise HTTP requests and configuration for advanced cases.',
    useCases: [
      UseCase(
        name: 'Network request success',
        prompt: 'Send a GET request that should return HTTP 200.',
        action: DemoAction.networkSuccess,
        snippetKey: 'Instrumenting network calls',
      ),
      UseCase(
        name: 'Network request POST',
        prompt: 'Send a POST request with headers and a JSON payload.',
        action: DemoAction.networkPost,
        snippetKey: 'Instrumenting network calls',
      ),
      UseCase(
        name: 'Excluded URL patterns',
        prompt: 'Review URL exclusion support in the Splunk Flutter agent.',
        action: DemoAction.excludedUrls,
        snippetKey: 'Excluded URL patterns',
      ),
    ],
  ),
  Category(
    name: 'Error Conditions',
    caption:
        'Create controlled failures and understand what the mobile agents report.',
    useCases: [
      UseCase(
        name: 'Network request 404',
        prompt: 'Send a request that returns HTTP 404.',
        action: DemoAction.network404,
        snippetKey: 'Instrumenting network calls',
      ),
      UseCase(
        name: 'Network request 500',
        prompt: 'Send a request that returns HTTP 500.',
        action: DemoAction.network500,
        snippetKey: 'Instrumenting network calls',
      ),
      UseCase(
        name: 'Network request timeout',
        prompt: 'Use a short timeout to demonstrate a transport failure.',
        action: DemoAction.networkTimeout,
        snippetKey: 'Network request timeout',
      ),
      UseCase(
        name: 'Report error',
        prompt: 'Report a controlled, caught Dart exception through the agent.',
        action: DemoAction.reportError,
        snippetKey: 'Reporting selected errors',
      ),
      UseCase(
        name: 'Application not responding (ANR)',
        prompt:
            'Debug-only main-thread sleep used to trigger ANR/app-hang detection.',
        action: DemoAction.anr,
        snippetKey: 'ANR',
      ),
      UseCase(
        name: 'Crash reporting',
        prompt:
            'Deliberate native crash via a native MethodChannel, since '
            'splunk_otel_flutter has no Dart-level crash API. Verify with a '
            'profile build relaunched from the home screen after the crash.',
        action: DemoAction.crash,
        snippetKey: 'Crash reporting',
      ),
      UseCase(
        name: 'Report all crashes (async error)',
        prompt:
            'Debug-only error thrown outside a try/catch, asynchronously, '
            'to prove the zone-level handler reports errors that '
            'FlutterError.onError alone would miss.',
        action: DemoAction.reportAllCrashes,
        snippetKey: 'Report all crashes',
      ),
    ],
  ),
  Category(
    name: 'Session Replay',
    caption:
        'Record user sessions for visual playback in Splunk Observability Cloud.',
    useCases: [
      UseCase(
        name: 'Recording status',
        prompt:
            'Check whether session replay is currently recording, and why '
            'not if it isn\'t (e.g. not sampled, low storage).',
        action: DemoAction.sessionReplayStatus,
        snippetKey: 'Session replay status',
      ),
      UseCase(
        name: 'Mask sensitive content',
        prompt:
            'Toggle a demo masking rectangle on and off to hide sensitive '
            'UI from the recording.',
        action: DemoAction.sessionReplayMask,
        snippetKey: 'Session replay masking',
      ),
    ],
  ),
];
