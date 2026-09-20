import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xurmo/core/utils/auth_error_messages.dart';
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

/// The single entry point for email authentication.
///
/// Screens must not call Firebase Auth directly. Going through this class
/// keeps error handling in one place and means a future change, such as
/// adding phone login or a different backend, touches one file.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Signs in with email and password.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _guard(() => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ));
  }

  /// Creates the Firebase Auth account and its profile document in one step.
  ///
  /// New accounts always get the [UserRole.user] role. If the profile write
  /// fails after the account was created, the account is removed so the user
  /// can try again without hitting "email already in use".
  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user!;
      try {
        await user.updateDisplayName(name.trim());
        await _firestore.collection('users').doc(user.uid).set({
          'name': name.trim(),
          'email': email.trim(),
          'role': UserRole.user,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        await user.delete();
        rethrow;
      }

      return credential;
    });
  }

  /// Sends Firebase's password reset email.
  Future<void> sendPasswordReset({required String email}) {
    return _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  Future<void> signOut() => _guard(() => _auth.signOut());

  /// Runs [action] and converts any error into an [AuthFailure].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(authErrorMessage(e.code), code: e.code);
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
