import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
/// Two ways to identify an account are supported, both with a password:
///   - email, used as-is;
///   - phone number, without SMS. The number is normalized and turned into a
///     synthetic email (see phone_number.dart) that Firebase treats like any
///     other email account.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

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

  // ------------------------------------------------------------- Shared

  Future<void> signOut() => _guard(() => _auth.signOut());

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
