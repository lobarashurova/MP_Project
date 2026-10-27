import 'package:flutter_test/flutter_test.dart';
import 'package:xurmo/core/utils/auth_error_messages.dart';
import 'package:xurmo/data/models/auth_method.dart';
import 'package:xurmo/data/models/user_role.dart';

void main() {
  group('authErrorMessage', () {
    test('treats every wrong-credential code as the same message', () {
      final message = authErrorMessage('invalid-credential');
      expect(authErrorMessage('wrong-password'), message);
      expect(authErrorMessage('user-not-found'), message);
      expect(authErrorMessage('invalid-login-credentials'), message);
      expect(message, contains('Incorrect email or password'));
    });

    test('explains a duplicate email at sign-up', () {
      expect(authErrorMessage('email-already-in-use'), contains('already exists'));
    });

    test('explains a weak password at sign-up', () {
      expect(authErrorMessage('weak-password'), contains('stronger password'));
    });

    test('explains a missing network connection', () {
      expect(authErrorMessage('network-request-failed'), contains('internet'));
    });

    test('never leaks the raw code for unknown errors', () {
      final message = authErrorMessage('some-new-firebase-code');
      expect(message, isNot(contains('some-new-firebase-code')));
      expect(message, isNotEmpty);
    });

    test('handles a null code', () {
      expect(authErrorMessage(null), isNotEmpty);
    });

    test('rewords identifier errors for phone accounts', () {
      expect(authErrorMessage('invalid-credential', phone: true),
          'Incorrect phone number or password.');
      expect(authErrorMessage('email-already-in-use', phone: true),
          contains('phone number already exists'));
      expect(authErrorMessage('invalid-email', phone: true),
          'Enter a valid phone number.');
      // Messages that do not mention the identifier are unchanged.
      expect(authErrorMessage('weak-password', phone: true),
          authErrorMessage('weak-password'));
    });
  });

  group('Google sign-in messages', () {
    test('explains an email already registered with a password', () {
      expect(authErrorMessage('account-exists-with-different-credential'),
          contains('Sign in with email and password'));
    });

    test('explains when Google sign-in is not set up', () {
      expect(authErrorMessage('google-not-configured'), contains('not set up'));
    });
  });

  group('AuthMethod.fromStorage', () {
    test('reads every stored method', () {
      for (final method in AuthMethod.values) {
        expect(AuthMethod.fromStorage(method.storageValue), method);
      }
    });

    test('treats a missing or unknown value as email', () {
      expect(AuthMethod.fromStorage(null), AuthMethod.email);
      expect(AuthMethod.fromStorage('fax'), AuthMethod.email);
    });
  });

  group('UserRole', () {
    test('lists the four sides of the app', () {
      expect(UserRole.all, ['user', 'courier', 'restaurant', 'admin']);
    });
  });
}
