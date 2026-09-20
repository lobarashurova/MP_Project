/// Maps Firebase Auth error codes to short messages a customer can act on.
///
/// Firebase's own messages are written for developers ("The supplied auth
/// credential is malformed or has expired"). These are written for the person
/// holding the phone. Unknown codes fall back to a generic message.
String authErrorMessage(String? code) {
  switch (code) {
    // Sign in
    case 'invalid-credential':
    case 'invalid-login-credentials':
    case 'wrong-password':
    case 'user-not-found':
      return 'Incorrect email or password.';
    case 'invalid-email':
    case 'missing-email':
      return 'Enter a valid email address.';
    case 'user-disabled':
      return 'This account has been disabled. Contact support for help.';

    // Sign up
    case 'email-already-in-use':
      return 'An account with this email already exists. Try signing in.';
    case 'weak-password':
      return 'Choose a stronger password with at least 6 characters.';
    case 'operation-not-allowed':
      return 'Email sign-in is not enabled right now. Try again later.';

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
