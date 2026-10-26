import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/models.dart';

class DemoNetworkClient {
  DemoNetworkClient({
    required http.Client client,
    required String baseUrl,
    this.timeout = const Duration(seconds: 2),
  }) : _client = client,
       _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;
  final Duration timeout;

  Future<DemoResult> execute(DemoAction action) async {
    try {
      final response = switch (action) {
        DemoAction.networkSuccess => _client.get(_uri('/status/200')),
        DemoAction.networkPost => _client.post(
          _uri('/post'),
          headers: {
            'Content-Type': 'application/json',
            'X-Sample-Scenario': 'network-post',
          },
          body: jsonEncode({'scenario': 'splunk-sample', 'source': 'flutter'}),
        ),
        DemoAction.network404 => _client.get(_uri('/status/404')),
        DemoAction.network500 => _client.get(_uri('/status/500')),
        DemoAction.networkTimeout => _client.get(_uri('/delay/20')),
        _ => throw ArgumentError('Unsupported network action: $action'),
      };
      final completed = await response.timeout(
        action == DemoAction.networkTimeout
            ? timeout
            : const Duration(seconds: 10),
      );
      if (completed.statusCode >= 200 && completed.statusCode < 300) {
        return DemoResult(
          DemoStatus.success,
          'HTTP ${completed.statusCode} received',
        );
      }
      return DemoResult(
        DemoStatus.failure,
        'HTTP ${completed.statusCode} received and recorded as a network error',
      );
    } on TimeoutException {
      return const DemoResult(
        DemoStatus.failure,
        'Transport failure: request timed out',
      );
    } on Exception catch (error) {
      return DemoResult(DemoStatus.failure, 'Transport failure: $error');
    }
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  void close() => _client.close();
}
