import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> placeOrder(List<Map<String, dynamic>> cartItems, double totalAmount) async {
    final uid = _auth.currentUser!.uid;

    await _firestore.collection('orders').add({
      'userId': uid,
      'items': cartItems,
      'total': totalAmount,
      'status': 'preparing',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}