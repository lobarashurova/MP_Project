import 'package:flutter_test/flutter_test.dart';
import 'package:xurmo/core/utils/auth_error_messages.dart';
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
  });

  group('UserRole', () {
    test('lists the four sides of the app', () {
      expect(UserRole.all, ['user', 'courier', 'restaurant', 'admin']);
    });
  });
}
