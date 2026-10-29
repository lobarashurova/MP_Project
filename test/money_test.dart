import 'package:flutter_test/flutter_test.dart';
import 'package:xurmo/core/utils/money.dart';

void main() {
  group('formatSum', () {
    test('groups thousands with spaces, drops decimals, appends the unit', () {
      expect(formatSum(20000), '20 000 soʻm');
      expect(formatSum(100000), '100 000 soʻm');
      expect(formatSum(45500.6), '45 501 soʻm');
    });
  });

  group('normalizeLegacySum', () {
    test('scales up dollar-scale prices stored before the move to sums', () {
      expect(normalizeLegacySum(56), 56000);
    });

    test('leaves prices already in sums alone', () {
      expect(normalizeLegacySum(20000), 20000);
    });

    test('leaves zero and negatives alone', () {
      expect(normalizeLegacySum(0), 0);
      expect(normalizeLegacySum(-5), -5);
    });
  });
}
