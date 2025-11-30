import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';
import 'package:xurmo/data/manager/favorites_manager.dart';
import 'package:xurmo/presentation/basket/cart.dart';
import 'package:xurmo/presentation/profile/personal_info_page.dart';
import 'package:xurmo/presentation/orders/order_page.dart';
import 'package:xurmo/presentation/profile/about_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FavoritesManager _favoritesManager = FavoritesManager();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  int _orderCount = 0;

  @override
  void initState() {
    super.initState();
    _favoritesManager.addListener(_onDataChanged);
    Cart.instance.notifier.addListener(_onDataChanged);
    _loadOrderCount();
  }

  @override
  void dispose() {
    _favoritesManager.removeListener(_onDataChanged);
    Cart.instance.notifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadOrderCount() async {
    if (_currentUser == null) return;
    final orders = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: _currentUser.uid)
        .get();
    setState(() => _orderCount = orders.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStatsSection(),
              const SizedBox(height: 24),
              _buildAccountSection(),
              const SizedBox(height: 16),
              _buildSettingsSection(),
              const SizedBox(height: 24),
              _buildLogoutButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Icon(CupertinoIcons.person_fill, size: 40, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_currentUser?.uid)
                  .get(),
              builder: (context, snapshot) {
                String name = 'User';
                String email = _currentUser?.email ?? 'No email';

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  name = data['name'] ?? 'User';
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.heading2),
                    const SizedBox(height: 4),
                    Text(email, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const PersonalInformationPage(),
                      )),
                      child: Text('Edit Profile', style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w600,
                      )),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard(CupertinoIcons.heart_fill, _favoritesManager.favoriteCount.toString(), 'Favorites', AppColors.error)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(CupertinoIcons.cart_fill, Cart.instance.totalItems.toString(), 'In Cart', AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(CupertinoIcons.cube_box_fill, _orderCount.toString(), 'Orders', AppColors.success)),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.heading2.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return _buildSection('Account', [
      _buildMenuItem(CupertinoIcons.person, 'Personal Information', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInformationPage()))),
      _buildMenuItem(CupertinoIcons.time, 'Order History', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersPage())).then((_) => _loadOrderCount())),
    ]);
  }

  Widget _buildSettingsSection() {
    return _buildSection('Settings', [
      _buildSwitchItem(CupertinoIcons.bell, 'Notifications', _notificationsEnabled, (val) => setState(() => _notificationsEnabled = val)),
      _buildSwitchItem(CupertinoIcons.moon, 'Dark Mode', _darkModeEnabled, (val) {
        setState(() => _darkModeEnabled = val);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dark mode coming soon!', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.primary),
        );
      }),
      _buildMenuItem(CupertinoIcons.globe, 'Language', () => _showComingSoon('Language'), trailing: 'English'),
      _buildMenuItem(CupertinoIcons.info_circle, 'About', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage())), trailing: 'v1.0.0'),
    ]);
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(title, style: AppTextStyles.heading3.copyWith(color: AppColors.textSecondary, fontSize: 14)),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.shadow.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {String? trailing}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.iconPrimary),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: AppTextStyles.bodyMedium)),
            if (trailing != null) ...[
              Text(trailing, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(width: 8),
            ],
            Icon(CupertinoIcons.chevron_right, size: 18, color: AppColors.iconSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.iconPrimary),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: AppTextStyles.bodyMedium)),
          CupertinoSwitch(value: value, activeColor: AppColors.primary, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _showLogoutDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.square_arrow_right, size: 20),
              const SizedBox(width: 8),
              Text('Logout', style: AppTextStyles.button),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature feature coming soon!', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.primary),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout', style: AppTextStyles.heading3),
        content: Text('Are you sure you want to logout?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}