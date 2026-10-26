import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

import '../config/app_config.dart';
import '../data/models.dart';
import '../data/sample_catalog.dart';
import '../data/snippet_repository.dart';
import '../demo/demo_controller.dart';
import '../instrumentation/splunk_bridge.dart';
import '../network/demo_network_client.dart';

class SampleApp extends StatefulWidget {
  const SampleApp({super.key, required this.config, required this.bridge});

  final AppConfig config;
  final InstrumentationBridge bridge;

  @override
  State<SampleApp> createState() => _SampleAppState();
}

class _SampleAppState extends State<SampleApp> {
  late final DemoNetworkClient _networkClient;
  late final DemoController _controller;
  final _snippets = SnippetRepository();

  @override
  void initState() {
    super.initState();
    _networkClient = DemoNetworkClient(
      client: widget.bridge.createHttpClient(),
      baseUrl: widget.config.demoBaseUrl,
    );
    _controller = DemoController(widget.bridge, _networkClient);
  }

  @override
  void dispose() {
    _networkClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splunk Sample',
      debugShowCheckedModeBanner: false,
      theme: _theme,
      initialRoute: '/',
      navigatorObservers: widget.bridge.isConfigured
          ? <NavigatorObserver>[SplunkNavigatorObserver()]
          : const <NavigatorObserver>[],
      onGenerateRoute: _route,
    );
  }

  Route<void> _route(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      '/' => HomeScreen(bridge: widget.bridge),
      '/category' => CategoryScreen(category: settings.arguments! as Category),
      '/demo' => DemoScreen(
        useCase: settings.arguments! as UseCase,
        controller: _controller,
      ),
      '/snippet' => SnippetScreen(
        useCase: settings.arguments! as UseCase,
        repository: _snippets,
      ),
      '/next' => NextStepsScreen(
        useCase: settings.arguments! as UseCase,
        demoBaseUrl: widget.config.demoBaseUrl,
      ),
      _ => const Scaffold(body: Center(child: Text('Route not found.'))),
    };
    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }
}

final _theme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF006C67),
    primary: const Color(0xFF006C67),
    secondary: const Color(0xFFC04F24),
    surface: const Color(0xFFFFFBF5),
  ),
  scaffoldBackgroundColor: const Color(0xFFF4F0E8),
  cardTheme: const CardThemeData(
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
      side: BorderSide(color: Color(0xFFD7D2C8)),
    ),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    backgroundColor: Color(0xFFF4F0E8),
    surfaceTintColor: Colors.transparent,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  ),
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.bridge});

  final InstrumentationBridge bridge;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Splunk Sample',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF173F3B),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instrumentation lab',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Run mobile telemetry scenarios from one Flutter codebase.',
                  style: TextStyle(color: Color(0xFFD8E8E5), fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _AgentStatus(bridge: bridge),
          const SizedBox(height: 24),
          Text('Scenarios', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final category in sampleCatalog) ...[
            _CategoryCard(category: category),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _AgentStatus extends StatelessWidget {
  const _AgentStatus({required this.bridge});

  final InstrumentationBridge bridge;

  @override
  Widget build(BuildContext context) {
    final color = bridge.isConfigured
        ? const Color(0xFF2E6B45)
        : const Color(0xFF8A5A00);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            bridge.isConfigured ? Icons.sensors : Icons.sensors_off,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(bridge.startupMessage)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final icon = switch (category.name) {
      'Features' => Icons.tune,
      'Networking' => Icons.language,
      'Session Replay' => Icons.videocam_outlined,
      _ => Icons.warning_amber,
    };
    return Card(
      child: InkWell(
        key: Key('category-${category.name}'),
        borderRadius: BorderRadius.circular(6),
        onTap: () =>
            Navigator.pushNamed(context, '/category', arguments: category),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('${category.useCases.length} scenarios'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: category.name,
      showBack: true,
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: category.useCases.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                category.caption,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          final useCase = category.useCases[index - 1];
          return Card(
            child: ListTile(
              key: Key('use-case-${index - 1}'),
              contentPadding: const EdgeInsets.all(14),
              title: Text(useCase.name),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(useCase.prompt),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.pushNamed(context, '/demo', arguments: useCase),
            ),
          );
        },
      ),
    );
  }
}

class DemoScreen extends StatefulWidget {
  const DemoScreen({
    super.key,
    required this.useCase,
    required this.controller,
  });

  final UseCase useCase;
  final DemoController controller;

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  DemoResult? _result;
  bool _running = false;

  Future<void> _run() async {
    setState(() => _running = true);
    try {
      final result = await widget.controller.run(widget.useCase);
      if (mounted) {
        setState(() => _result = result);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _result = DemoResult(
            DemoStatus.failure,
            'Demonstration failed: $error',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: widget.useCase.name,
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            widget.useCase.prompt,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('run-demo'),
            onPressed: _running ? null : _run,
            icon: _running
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_running ? 'Running...' : 'Run demonstration'),
          ),
          if (_result case final result?) ...[
            const SizedBox(height: 16),
            _ResultPanel(result: result),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/snippet',
                  arguments: widget.useCase,
                ),
                icon: const Icon(Icons.code),
                label: const Text('View Dart'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/next',
                  arguments: widget.useCase,
                ),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Next steps'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.result});

  final DemoResult result;

  @override
  Widget build(BuildContext context) {
    final success = result.status == DemoStatus.success;
    final color = success
        ? const Color(0xFF2E6B45)
        : Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            success ? 'SUCCESS' : 'FAILURE',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(result.message),
        ],
      ),
    );
  }
}

class SnippetScreen extends StatefulWidget {
  const SnippetScreen({
    super.key,
    required this.useCase,
    required this.repository,
  });

  final UseCase useCase;
  final SnippetRepository repository;

  @override
  State<SnippetScreen> createState() => _SnippetScreenState();
}

class _SnippetScreenState extends State<SnippetScreen> {
  late final Future<String> _snippet;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _snippet = widget.repository.get(widget.useCase.snippetKey);
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Dart: ${widget.useCase.name}',
      showBack: true,
      body: FutureBuilder<String>(
        future: _snippet,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final snippet = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton.filledTonal(
                  key: const Key('copy-snippet'),
                  tooltip: _copied ? 'Copied' : 'Copy snippet',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: snippet));
                    if (mounted) {
                      setState(() => _copied = true);
                    }
                  },
                  icon: Icon(_copied ? Icons.check : Icons.copy),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF202826),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SelectableText(
                  snippet,
                  style: const TextStyle(
                    color: Color(0xFFE5EEE9),
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class NextStepsScreen extends StatelessWidget {
  const NextStepsScreen({
    super.key,
    required this.useCase,
    required this.demoBaseUrl,
  });

  final UseCase useCase;
  final String demoBaseUrl;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Next steps',
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(useCase.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(useCase.nextSteps),
          const SizedBox(height: 24),
          Text('Debug output', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          const SelectableText('flutter logs | grep -i splunk'),
          const SizedBox(height: 20),
          Text('Demo endpoint', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          SelectableText(demoBaseUrl),
          const SizedBox(height: 6),
          const Text(
            'For a server on the development Mac, Android Emulator uses 10.0.2.2, iOS Simulator uses localhost, and a physical iOS device uses the Mac LAN address.',
          ),
        ],
      ),
    );
  }
}

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBack = false,
  });

  final String title;
  final Widget body;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), automaticallyImplyLeading: showBack),
      body: SafeArea(child: body),
    );
  }
}
