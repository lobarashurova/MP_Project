import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:xurmo/core/utils/auth_error_messages.dart';
import 'package:xurmo/core/utils/phone_number.dart';
import 'package:xurmo/data/models/auth_method.dart';
import 'package:xurmo/data/models/user_role.dart';

/// Thrown by [AuthRepository] with a message that is safe to show in the UI.
class AuthFailure implements Exception {
  final String message;

  /// The underlying Firebase error code, kept for logging and tests.
  final String? code;

  const AuthFailure(this.message, {this.code});

  @override
  String toString() => message;
}

/// The single entry point for authentication.
///
/// Screens must not call Firebase Auth directly. Going through this class
/// keeps error handling in one place and means a future change, such as SMS
/// verification or a different backend, touches one file.
///
/// Three ways to sign in are supported:
///   - email and password, used as-is;
///   - phone number and password, without SMS. The number is normalized and
///     turned into a synthetic email (see phone_number.dart) that Firebase
///     treats like any other email account;
///   - Google, through the Google account picker. The first Google sign-in
///     also creates the user's profile, so it doubles as registration.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _google;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? google,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _google = google ?? GoogleSignIn.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // ---------------------------------------------------------------- Email

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _guard(() => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ));
  }

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _guard(() => _createAccount(
          loginEmail: email.trim(),
          password: password,
          profile: {
            'name': name.trim(),
            'email': email.trim(),
            'phone': '',
            'authMethod': AuthMethod.email.storageValue,
          },
        ));
  }

  /// Sends Firebase's password reset email. Only email accounts can receive
  /// one; phone accounts have no inbox behind their synthetic address.
  Future<void> sendPasswordReset({required String email}) {
    if (isSyntheticEmail(email)) {
      throw const AuthFailure(
        'Password reset is not available for phone accounts yet.',
      );
    }
    return _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  // ---------------------------------------------------------------- Phone

  Future<UserCredential> signInWithPhone({
    required String phone,
    required String password,
  }) {
    final e164 = _requireValidPhone(phone);
    return _guard(
      () => _auth.signInWithEmailAndPassword(
        email: phoneToSyntheticEmail(e164),
        password: password,
      ),
      phone: true,
    );
  }

  Future<UserCredential> signUpWithPhone({
    required String name,
    required String phone,
    required String password,
  }) {
    final e164 = _requireValidPhone(phone);
    return _guard(
      () => _createAccount(
        loginEmail: phoneToSyntheticEmail(e164),
        password: password,
        profile: {
          'name': name.trim(),
          'email': '',
          'phone': e164,
          'authMethod': AuthMethod.phone.storageValue,
        },
      ),
      phone: true,
    );
  }

  String _requireValidPhone(String input) {
    final e164 = normalizePhone(input);
    if (e164 == null) {
      throw const AuthFailure('Enter a valid phone number.', code: 'invalid-phone');
    }
    return e164;
  }

  // --------------------------------------------------------------- Google

  /// GoogleSignIn must be initialized exactly once per app run.
  static Future<void>? _googleInit;

  /// Signs in with a Google account, creating the profile on first use.
  ///
  /// Returns null when the person closes the account picker, so the caller
  /// can simply do nothing.
  Future<UserCredential?> signInWithGoogle() {
    return _guard(() async {
      if (!_google.supportsAuthenticate()) {
        throw const AuthFailure(
          'Google sign-in is not available on this device.',
          code: 'google-unavailable',
        );
      }

      // On Android the client ID comes from google-services.json, which must
      // contain the web OAuth client that Firebase adds when Google sign-in
      // is enabled.
      _googleInit ??= _google.initialize();
      try {
        await _googleInit;
      } catch (_) {
        // Allow a retry on the next tap instead of failing forever.
        _googleInit = null;
        throw AuthFailure(authErrorMessage('google-not-configured'),
            code: 'google-not-configured');
      }

      final GoogleSignInAccount account;
      try {
        account = await _google.authenticate();
      } on GoogleSignInException catch (e) {
        switch (e.code) {
          case GoogleSignInExceptionCode.canceled:
          case GoogleSignInExceptionCode.interrupted:
            return null;
          case GoogleSignInExceptionCode.clientConfigurationError:
          case GoogleSignInExceptionCode.providerConfigurationError:
            throw AuthFailure(authErrorMessage('google-not-configured'),
                code: 'google-not-configured');
          case GoogleSignInExceptionCode.uiUnavailable:
            throw AuthFailure(authErrorMessage('google-unavailable'),
                code: 'google-unavailable');
          default:
            throw AuthFailure(authErrorMessage('google-failed'), code: 'google-failed');
        }
      }

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw AuthFailure(authErrorMessage('google-not-configured'),
            code: 'google-not-configured');
      }

      final credential = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      await _ensureGoogleProfile(credential.user!);
      return credential;
    });
  }

  /// Creates the profile document the first time a Google account signs in.
  /// Existing profiles are left alone, so a role set by an admin is kept.
  Future<void> _ensureGoogleProfile(User user) async {
    final ref = _firestore.collection('users').doc(user.uid);
    if ((await ref.get()).exists) return;

    await ref.set({
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'phone': '',
      'authMethod': AuthMethod.google.storageValue,
      'role': UserRole.user,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------- Shared

  Future<void> signOut() => _guard(() async {
        await _auth.signOut();
        // Forget the chosen Google account too, so the next Google sign-in
        // shows the account picker instead of reusing the last account.
        // Ignored when Google was never used in this run.
        if (_googleInit != null) {
          try {
            await _google.signOut();
          } catch (_) {}
        }
      });

  /// Creates the Firebase Auth account and its profile document in one step.
  ///
  /// New accounts always get the [UserRole.user] role. If the profile write
  /// fails after the account was created, the account is removed so the user
  /// can try again without hitting "already in use".
  Future<UserCredential> _createAccount({
    required String loginEmail,
    required String password,
    required Map<String, dynamic> profile,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: loginEmail,
      password: password,
    );

    final user = credential.user!;
    try {
      await user.updateDisplayName(profile['name'] as String);
      await _firestore.collection('users').doc(user.uid).set({
        ...profile,
        'role': UserRole.user,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      await user.delete();
      rethrow;
    }

    return credential;
  }

  /// Runs [action] and converts any error into an [AuthFailure].
  Future<T> _guard<T>(Future<T> Function() action, {bool phone = false}) async {
    try {
      return await action();
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(authErrorMessage(e.code, phone: phone), code: e.code);
    } on FirebaseException catch (e) {
      throw AuthFailure(
        'Could not save your account details. Please try again.',
        code: e.code,
      );
    } catch (_) {
      throw const AuthFailure('Something went wrong. Please try again.');
    }
  }
}
