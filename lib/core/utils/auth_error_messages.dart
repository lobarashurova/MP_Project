/// Maps Firebase Auth error codes to short messages a customer can act on.
///
/// Firebase's own messages are written for developers ("The supplied auth
/// credential is malformed or has expired"). These are written for the person
/// holding the phone. Unknown codes fall back to a generic message.
///
/// Phone accounts are email accounts underneath (see phone_number.dart), so
/// Firebase reports their errors with email wording. Pass [phone] to reword
/// them for the phone screens.
String authErrorMessage(String? code, {bool phone = false}) {
  final identifier = phone ? 'phone number' : 'email';

  switch (code) {
    // Sign in
    case 'invalid-credential':
    case 'invalid-login-credentials':
    case 'wrong-password':
    case 'user-not-found':
      return 'Incorrect $identifier or password.';
    case 'invalid-email':
    case 'missing-email':
      return phone
          ? 'Enter a valid phone number.'
          : 'Enter a valid email address.';
    case 'user-disabled':
      return 'This account has been disabled. Contact support for help.';

    // Sign up
    case 'email-already-in-use':
      return 'An account with this $identifier already exists. Try signing in.';
    case 'weak-password':
      return 'Choose a stronger password with at least 6 characters.';
    case 'operation-not-allowed':
      return 'Sign-in is not enabled right now. Try again later.';

    // Google sign-in
    case 'account-exists-with-different-credential':
      return 'This email is already registered with a password. '
          'Sign in with email and password instead.';
    case 'google-not-configured':
      return 'Google sign-in is not set up for this app yet.';
    case 'google-unavailable':
      return 'Google sign-in is not available on this device.';
    case 'google-failed':
      return 'Google sign-in did not finish. Please try again.';

    // Shared
    case 'too-many-requests':
      return 'Too many attempts. Wait a moment and try again.';
    case 'network-request-failed':
      return 'No internet connection. Check your network and try again.';
    case 'requires-recent-login':
      return 'Please sign in again to continue.';

    default:
      return 'Something went wrong. Please try again.';
  }
}
