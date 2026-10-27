import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xurmo/core/errors/app_exception.dart';

class FavoritesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get isSignedIn => _auth.currentUser != null;

  CollectionReference get _favCollection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      // Without this guard a signed-out tap blows up on a null assertion.
      throw const AppException(
        AppErrorType.unauthorized,
        'Sign in to save your favorites.',
      );
    }
    return _firestore.collection('users').doc(uid).collection('favorites');
  }

  Future<void> addFavorite(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    try {
      await _favCollection.doc(productId).set(productData);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> removeFavorite(String productId) async {
    try {
      await _favCollection.doc(productId).delete();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Stream<List<Map<String, dynamic>>> getFavorites() {
    return _favCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }
}
