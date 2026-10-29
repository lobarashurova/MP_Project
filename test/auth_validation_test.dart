import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xurmo/presentation/auth/widgets/auth_fields.dart';

void main() {
  group('validateEmail', () {
    test('accepts ordinary addresses', () {
      expect(validateEmail('you@example.com'), isNull);
      expect(validateEmail('first.last+tag@sub.example.co.uk'), isNull);
      expect(validateEmail('  spaced@example.com  '), isNull, reason: 'trimmed');
    });

    test('rejects empty and malformed input', () {
      expect(validateEmail(null), 'Email is required');
      expect(validateEmail('   '), 'Email is required');
      expect(validateEmail('no-at-sign'), contains('valid email'));
      expect(validateEmail('no@tld'), contains('valid email'));
      expect(validateEmail('@example.com'), contains('valid email'));
      expect(validateEmail('two@@example.com'), contains('valid email'));
    });

    test('rejects an internal space', () {
      expect(validateEmail('a b@example.com'), contains('spaces'));
    });

    test('rejects the reserved phone-account domain', () {
      // These addresses are generated for phone sign-in and have no inbox.
      expect(
        validateEmail('998901234567@phone.xurmo.app'),
        contains('Phone tab'),
      );
    });
  });

  group('validatePassword', () {
    test('accepts six characters or more', () {
      expect(validatePassword('secret'), isNull);
      expect(validatePassword('a very long passphrase'), isNull);
    });

    test('rejects empty and short', () {
      expect(validatePassword(null), 'Password is required');
      expect(validatePassword(''), 'Password is required');
      expect(validatePassword('12345'), contains('at least 6'));
    });

    test('rejects leading or trailing whitespace', () {
      // Firebase would reject these with an error that explains nothing.
      expect(validatePassword(' secret'), contains('space'));
      expect(validatePassword('secret '), contains('space'));
    });
  });

  group('validateConfirmPassword', () {
    test('passes when both match', () {
      expect(validateConfirmPassword('secret', 'secret'), isNull);
    });

    test('reports a mismatch and an empty confirmation', () {
      expect(validateConfirmPassword('other', 'secret'), 'Passwords do not match');
      expect(validateConfirmPassword('', 'secret'), 'Confirm your password');
    });
  });

  group('validateName', () {
    test('accepts a real name and trims', () {
      expect(validateName('Ada Lovelace'), isNull);
      expect(validateName('  Ada  '), isNull);
    });

    test('rejects empty, single characters and overlong input', () {
      expect(validateName('  '), 'Name is required');
      expect(validateName('A'), contains('full name'));
      expect(validateName('x' * 61), contains('too long'));
    });
  });

  group('validatePhone', () {
    test('accepts local and full forms', () {
      expect(validatePhone('901234567'), isNull);
      expect(validatePhone('90 123 45 67'), isNull);
      expect(validatePhone('+998901234567'), isNull);
    });

    test('rejects empty and malformed numbers', () {
      expect(validatePhone(''), 'Phone number is required');
      expect(validatePhone('123'), contains('valid number'));
    });
  });

  group('field widgets', () {
    Widget wrap(Widget child) => MaterialApp(
          home: Scaffold(body: Form(child: child)),
        );

    testWidgets('EmailField accepts typing and surfaces its validator',
        (tester) async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: EmailField(controller: controller),
          ),
        ),
      ));

      await tester.enterText(find.byType(TextFormField), 'you@example.com');
      expect(controller.text, 'you@example.com');
      expect(formKey.currentState!.validate(), isTrue);

      await tester.enterText(find.byType(TextFormField), 'nope');
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.textContaining('valid email'), findsOneWidget);
    });

    testWidgets('a disabled field cannot be typed into', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        wrap(EmailField(controller: controller, enabled: false)),
      );

      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.enabled, isFalse);
    });

    testWidgets('PhoneField strips characters a number cannot contain',
        (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(wrap(PhoneField(controller: controller)));

      await tester.enterText(find.byType(TextFormField), '90abc123!45@67');
      expect(controller.text, '9012345 67'.replaceAll(' ', ''));
    });
  });
}
