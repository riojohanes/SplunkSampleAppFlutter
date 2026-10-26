import 'package:flutter_test/flutter_test.dart';
import 'package:splunk_sample_app_flutter/data/sample_catalog.dart';

void main() {
  test('catalog preserves the native samples learning surface', () {
    expect(sampleCatalog.map((category) => category.name), [
      'Features',
      'Networking',
      'Error Conditions',
      'Session Replay',
    ]);
    expect(
      sampleCatalog.fold<int>(
        0,
        (total, category) => total + category.useCases.length,
      ),
      19,
    );
    expect(
      sampleCatalog
          .expand((category) => category.useCases)
          .every((useCase) => useCase.snippetKey.isNotEmpty),
      isTrue,
    );
  });
}
