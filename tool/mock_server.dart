import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('Mock API listening on http://localhost:$port');

  await for (final request in server) {
    await _handleRequest(request);
  }
}

Future<void> _handleRequest(HttpRequest request) async {
  switch (request.method) {
    case 'GET' when request.uri.path == '/status/200':
      await _respond(request, HttpStatus.ok, {'status': 200});
    case 'POST' when request.uri.path == '/post':
      await request.drain<void>();
      await _respond(request, HttpStatus.ok, {'status': 200});
    case 'GET' when request.uri.path == '/status/404':
      await _respond(request, HttpStatus.notFound, {'status': 404});
    case 'GET' when request.uri.path == '/status/500':
      await _respond(request, HttpStatus.internalServerError, {'status': 500});
    case 'GET' when request.uri.path == '/delay/20':
      await Future<void>.delayed(const Duration(seconds: 20));
      await _respond(request, HttpStatus.ok, {'status': 200});
    default:
      await _respond(request, HttpStatus.notFound, {'status': 404});
  }
}

Future<void> _respond(
  HttpRequest request,
  int statusCode,
  Map<String, Object> body,
) async {
  final response = request.response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
  await response.close();
}
