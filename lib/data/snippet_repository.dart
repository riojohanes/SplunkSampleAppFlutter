import 'dart:convert';

import 'package:flutter/services.dart';

class SnippetRepository {
  Future<String> get(String key) async {
    final raw = await rootBundle.loadString('assets/flutter_snippets.json');
    final snippets = jsonDecode(raw) as List<dynamic>;
    for (final item in snippets.cast<Map<String, dynamic>>()) {
      if (item['name'] == key) {
        return item['content'] as String;
      }
    }
    return '// No snippet is available for $key.';
  }
}
