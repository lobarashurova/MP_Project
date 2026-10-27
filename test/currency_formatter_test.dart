import 'package:flutter_test/flutter_test.dart';
import 'package:xurmo/core/utils/currency_formatter.dart';

void main() {
  group('Uzbek som formatting', () {
    test('formats whole som with grouped thousands', () {
      expect(formatSom(20000), '20 000 soʻm');
      expect(formatSom(100000), '100 000 soʻm');
    });

    test('normalizes previously stored small price amounts', () {
      expect(normalizeLegacySomAmount(56), 56000);
      expect(normalizeLegacySomAmount(20000), 20000);
    });
  });
}
