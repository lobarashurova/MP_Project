import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _favCollection {
    final uid = _auth.currentUser!.uid;
    return _firestore.collection('users').doc(uid).collection('favorites');
  }

  Future<void> addFavorite(String productId, Map<String, dynamic> productData) async {
    await _favCollection.doc(productId).set(productData);
  }

  Future<void> removeFavorite(String productId) async {
    await _favCollection.doc(productId).delete();
  }

  Stream<List<Map<String, dynamic>>> getFavorites() {
    return _favCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }
}