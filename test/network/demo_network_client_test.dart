import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:splunk_sample_app_flutter/data/models.dart';
import 'package:splunk_sample_app_flutter/network/demo_network_client.dart';

void main() {
  test('successful GET uses the expected status path', () async {
    http.Request? captured;
    final client = DemoNetworkClient(
      client: MockClient((request) async {
        captured = request;
        return http.Response('', 200);
      }),
      baseUrl: 'https://example.test',
    );

    final result = await client.execute(DemoAction.networkSuccess);

    expect(result.status, DemoStatus.success);
    expect(captured?.url.path, '/status/200');
    client.close();
  });

  test('HTTP errors remain failures with their status code', () async {
    final client = DemoNetworkClient(
      client: MockClient((_) async => http.Response('', 404)),
      baseUrl: 'https://example.test',
    );

    final result = await client.execute(DemoAction.network404);

    expect(result.status, DemoStatus.failure);
    expect(result.message, contains('HTTP 404'));
    client.close();
  });

  test('timeout is reported as a transport failure', () async {
    final client = DemoNetworkClient(
      client: MockClient((_) => Completer<http.Response>().future),
      baseUrl: 'https://example.test',
      timeout: const Duration(milliseconds: 1),
    );

    final result = await client.execute(DemoAction.networkTimeout);

    expect(result.status, DemoStatus.failure);
    expect(result.message, contains('timed out'));
    client.close();
  });
}
