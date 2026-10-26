import 'dart:async';

import 'package:flutter/widgets.dart';

import 'config/app_config.dart';
import 'instrumentation/splunk_bridge.dart';
import 'ui/sample_app.dart';

void main() {
  final config = AppConfig.fromEnvironment();
  final bridge = SplunkBridge(config);

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await bridge.initialize();
      runApp(SampleApp(config: config, bridge: bridge));
    },
    (error, stackTrace) => unawaited(bridge.reportZoneError(error, stackTrace)),
  );
}
