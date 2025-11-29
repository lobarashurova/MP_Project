import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          final data = doc.data();
          setState(() {
            // _userName = data?['name'] ?? 'User';

            // Optional: If you want to show only the first name
            _userName = (data?['name'] ?? 'User').split(' ')[0];
          });
        }
      } catch (e) {
        debugPrint("Error fetching name: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $_userName',
            style: AppTextStyles.heading1,
          ),
          const SizedBox(height: 4),
          Text(
            'What would you like to eat today?',
            style: AppTextStyles.subtitle,
          ),
        ],
      ),
    );
  }
}