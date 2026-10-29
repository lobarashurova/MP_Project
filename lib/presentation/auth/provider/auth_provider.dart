import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xurmo/data/repositories/auth_repository.dart';

/// Exposes the signed-in user to the widget tree and forwards every auth
/// action to [AuthRepository]. Screens call this, never Firebase directly.
///
/// All actions throw [AuthFailure] with a message that is safe to show.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  StreamSubscription<User?>? _authSubscription;

  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepository() {
    _user = _repository.currentUser;
    _authSubscription = _repository.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> signIn({required String email, required String password}) {
    return _run(() => _repository.signIn(email: email, password: password));
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _run(() => _repository.signUp(
          name: name,
          email: email,
          password: password,
        ));
  }

  Future<void> signInWithPhone({required String phone, required String password}) {
    return _run(() => _repository.signInWithPhone(phone: phone, password: password));
  }

  Future<void> signUpWithPhone({
    required String name,
    required String phone,
    required String password,
  }) {
    return _run(() => _repository.signUpWithPhone(
          name: name,
          phone: phone,
          password: password,
        ));
  }

  Future<void> sendPasswordReset({required String email}) {
    return _run(() => _repository.sendPasswordReset(email: email));
  }

  Future<void> logout() => _run(_repository.signOut);

  Future<void> _run(Future<void> Function() action) async {
    _isLoading = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
