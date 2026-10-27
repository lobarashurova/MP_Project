import 'package:flutter_test/flutter_test.dart';
import 'package:xurmo/core/utils/phone_number.dart';

void main() {
  group('normalizePhone', () {
    test('adds +998 to a 9-digit local number', () {
      expect(normalizePhone('901234567'), '+998901234567');
    });

    test('accepts local formatting with spaces and dashes', () {
      expect(normalizePhone('90 123 45 67'), '+998901234567');
      expect(normalizePhone('90-123-45-67'), '+998901234567');
      expect(normalizePhone('(90) 123 45 67'), '+998901234567');
    });

    test('keeps a number typed with the country code', () {
      expect(normalizePhone('+998 90 123 45 67'), '+998901234567');
      expect(normalizePhone('998901234567'), '+998901234567');
    });

    test('accepts other international numbers with a plus', () {
      expect(normalizePhone('+7 999 123 45 67'), '+79991234567');
      expect(normalizePhone('+1 (415) 555 0132'), '+14155550132');
    });

    test('rejects input that cannot be a phone number', () {
      expect(normalizePhone(''), isNull);
      expect(normalizePhone('   '), isNull);
      expect(normalizePhone('abc'), isNull);
      expect(normalizePhone('12345'), isNull);
      expect(normalizePhone('+1'), isNull);
      expect(normalizePhone('+12345678901234567'), isNull);
    });
  });

  group('synthetic email', () {
    test('round-trips a phone number', () {
      const phone = '+998901234567';
      final email = phoneToSyntheticEmail(phone);
      expect(email, '998901234567@$phoneEmailDomain');
      expect(isSyntheticEmail(email), isTrue);
      expect(phoneFromSyntheticEmail(email), phone);
    });

    test('is stable for different spellings of the same number', () {
      final a = phoneToSyntheticEmail(normalizePhone('90 123 45 67')!);
      final b = phoneToSyntheticEmail(normalizePhone('+998901234567')!);
      expect(a, b);
    });

    test('does not treat real emails as synthetic', () {
      expect(isSyntheticEmail('someone@gmail.com'), isFalse);
      expect(isSyntheticEmail(null), isFalse);
      expect(phoneFromSyntheticEmail('someone@gmail.com'), isNull);
    });
  });

  group('formatPhoneForDisplay', () {
    test('groups Uzbek numbers the local way', () {
      expect(formatPhoneForDisplay('+998901234567'), '+998 90 123 45 67');
    });

    test('leaves other numbers alone', () {
      expect(formatPhoneForDisplay('+14155550132'), '+14155550132');
    });
  });
}
