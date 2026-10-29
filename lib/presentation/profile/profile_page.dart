import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';
import 'package:xurmo/core/theme/app_theme.dart';
import 'package:xurmo/core/widgets/app_card.dart';
import 'package:xurmo/core/utils/phone_number.dart';
import 'package:xurmo/core/theme/theme_provider.dart';
import 'package:xurmo/presentation/basket/cart.dart';
import 'package:xurmo/presentation/favorites/provider/favorites_provider.dart';
import 'package:xurmo/presentation/profile/personal_info_page.dart';
import 'package:xurmo/presentation/orders/order_page.dart';
import 'package:xurmo/presentation/profile/about_page.dart';
import 'package:xurmo/presentation/auth/pages/login_page.dart';
import 'package:xurmo/presentation/auth/provider/auth_provider.dart' as auth;
import 'package:xurmo/core/localization/app_strings.dart';
import 'package:xurmo/core/utils/haptics.dart';
import 'package:xurmo/presentation/profile/settings_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  /// The signed-in user for the current build. Read from AuthProvider on
  /// every build so the page follows login and logout without a restart.
  User? _currentUser;

  bool _notificationsEnabled = true;
  int _orderCount = 0;

  /// Which user the order count was last fetched for, so a login or a change
  /// of account triggers a fresh fetch.
  String? _orderCountUid;

  @override
  void initState() {
    super.initState();
    Cart.instance.notifier.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    Cart.instance.notifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  /// Re-fetches the order count for the signed-in user, e.g. after returning
  /// from the order history screen.
  void _refreshOrderCount() {
    final uid = _currentUser?.uid;
    if (uid != null) _loadOrderCount(uid);
  }

  Future<void> _loadOrderCount(String uid) async {
    _orderCountUid = uid;
    final orders = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .get();
    if (mounted && _orderCountUid == uid) {
      setState(() => _orderCount = orders.docs.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<auth.AuthProvider>(
      builder: (context, authProvider, _) {
        _currentUser = authProvider.user;

        if (!authProvider.isAuthenticated) {
          return _buildLoginView(context);
        }

        final uid = _currentUser!.uid;
        if (_orderCountUid != uid) {
          _loadOrderCount(uid);
        }

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceXl),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppTheme.spaceLg),
                  _buildStatsSection(),
                  const SizedBox(height: AppTheme.spaceLg),
                  _buildAccountSection(),
                  const SizedBox(height: AppTheme.spaceLg),
                  _buildSettingsSection(),
                  const SizedBox(height: AppTheme.spaceLg),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceLg,
        AppTheme.spaceLg,
        AppTheme.spaceLg,
        AppTheme.spaceXl,
      ),
      decoration: const BoxDecoration(
        // The gradient gives the tab a header that reads as the brand rather
        // than as one more white panel, and it works in both themes because
        // the orange is theme-independent.
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppTheme.radiusLarge + 8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.onPrimary.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            child: const Icon(
              CupertinoIcons.person_fill,
              size: 36,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_currentUser?.uid)
                  .get(),
              builder: (context, snapshot) {
                String name = 'User';
                // Phone accounts sign in through a synthetic email that must
                // never be shown, so prefer the profile's own contact fields.
                String contact = isSyntheticEmail(_currentUser?.email)
                    ? formatPhoneForDisplay(phoneFromSyntheticEmail(_currentUser?.email)!)
                    : (_currentUser?.email ?? 'No contact');

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  name = data['name'] ?? 'User';
                  final email = (data['email'] as String?) ?? '';
                  final phone = (data['phone'] as String?) ?? '';
                  if (email.isNotEmpty && !isSyntheticEmail(email)) {
                    contact = email;
                  } else if (phone.isNotEmpty) {
                    contact = formatPhoneForDisplay(phone);
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.onPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spaceXs),
                    Text(
                      contact,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spaceSm + 4),
                    // A pill rather than bare text: on the gradient a plain
                    // orange link would disappear.
                    GestureDetector(
                      onTap: () {
                        Haptics.tap();
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => const PersonalInformationPage(),
                        ));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceSm + 4,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.onPrimary.withValues(alpha: 0.22),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: Text(
                          context.tr('edit_profile'),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
    final favoriteCount = context.watch<FavoritesProvider>().favoriteCount;
    // Pulled up into the header so the two read as one unit instead of
    // leaving a band of empty background between them.
    return Transform.translate(
      offset: const Offset(0, -AppTheme.spaceLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildStatCard(CupertinoIcons.heart_fill, favoriteCount.toString(), context.tr('favorites'), AppColors.error)),
            const SizedBox(width: AppTheme.spaceSm + 4),
            Expanded(child: _buildStatCard(CupertinoIcons.cart_fill, Cart.instance.totalItems.toString(), context.tr('in_cart'), AppColors.primary)),
            const SizedBox(width: AppTheme.spaceSm + 4),
            Expanded(child: _buildStatCard(CupertinoIcons.cube_box_fill, _orderCount.toString(), context.tr('orders'), AppColors.success)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSm,
        vertical: AppTheme.spaceMd,
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: AppTheme.spaceSm + 2),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.subtitleSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return _buildSection(context.tr('account'), [
      _buildMenuItem(CupertinoIcons.person, context.tr('personal_info'), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInformationPage()))),
      _buildMenuItem(CupertinoIcons.time, context.tr('order_history'), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersPage())).then((_) => _refreshOrderCount())),
    ]);
  }

  Widget _buildSettingsSection() {
    final settings = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    String s(String k) => AppStrings.of(context, k);

    String fontLabel() {
      switch (settings.fontSize) {
        case AppFontSize.small:
          return s('small');
        case AppFontSize.medium:
          return s('medium');
        case AppFontSize.large:
          return s('large');
      }
    }

    return _buildSection(s('settings'), [
      _buildSwitchItem(CupertinoIcons.bell, s('notifications'), _notificationsEnabled, (val) => setState(() => _notificationsEnabled = val)),
      _buildSwitchItem(CupertinoIcons.moon, s('dark_mode'), themeProvider.isDarkMode, (val) {
        context.read<ThemeProvider>().toggleTheme(val);
      }),
      _buildMenuItem(CupertinoIcons.globe, s('language'), _showLanguageSheet, trailing: settings.languageName),
      _buildMenuItem(CupertinoIcons.textformat_size, s('font_size'), _showFontSheet, trailing: fontLabel()),
      _buildMenuItem(CupertinoIcons.info_circle, s('about'), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage())), trailing: 'v1.0.0'),
    ]);
  }

  void _showLanguageSheet() {
    final settings = context.read<SettingsProvider>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(AppStrings.of(context, 'choose_language'), style: AppTextStyles.heading3),
            ),
            for (final entry in SettingsProvider.languages.entries)
              ListTile(
                title: Text(entry.value),
                trailing: settings.locale.languageCode == entry.key
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  settings.setLocale(Locale(entry.key));
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showFontSheet() {
    final settings = context.read<SettingsProvider>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final options = {
          AppFontSize.small: AppStrings.of(ctx, 'small'),
          AppFontSize.medium: AppStrings.of(ctx, 'medium'),
          AppFontSize.large: AppStrings.of(ctx, 'large'),
        };
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(AppStrings.of(ctx, 'choose_font_size'),
                    style: AppTextStyles.heading3),
              ),
              for (final entry in options.entries)
                ListTile(
                  title: Text(entry.value),
                  trailing: settings.fontSize == entry.key
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    settings.setFontSize(entry.key);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return AppSection(title: title, children: children);
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {String? trailing}) {
    return InkWell(
      onTap: () {
        Haptics.tap();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMd,
          vertical: AppTheme.spaceSm + 4,
        ),
        child: Row(
          children: [
            _RowIcon(icon: icon),
            const SizedBox(width: AppTheme.spaceSm + 4),
            Expanded(child: Text(title, style: AppTextStyles.bodyMedium)),
            if (trailing != null) ...[
              Text(trailing, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(width: AppTheme.spaceSm),
            ],
            Icon(CupertinoIcons.chevron_right, size: 16, color: AppColors.iconSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: AppTheme.spaceXs + 1,
      ),
      child: Row(
        children: [
          _RowIcon(icon: icon),
          const SizedBox(width: AppTheme.spaceSm + 4),
          Expanded(child: Text(title, style: AppTextStyles.bodyMedium)),
          // Material Switch rather than CupertinoSwitch: it reads its colours
          // from switchTheme, so both themes stay in step and the deprecated
          // activeColor is gone.
          Switch(
            value: value,
            onChanged: (v) {
              Haptics.selection();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      child: OutlinedButton(
        onPressed: _showLogoutDialog,
        // Logging out is destructive, so it is outlined in the error colour
        // rather than wearing the same orange as "Order Now".
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.square_arrow_right, size: 20),
            const SizedBox(width: AppTheme.spaceSm),
            Text(
              context.trRead('logout'),
              style: AppTextStyles.button.copyWith(
                fontSize: 16,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    Haptics.tap();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.trRead('logout'), style: AppTextStyles.heading3),
        content: Text(context.trRead('logout_confirm'), style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(context.trRead('cancel'), style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              Haptics.warning();
              Navigator.pop(dialogContext);
              await context.read<auth.AuthProvider>().logout();
            },
            child: Text(context.trRead('logout'), style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  /// The profile tab shows the shared login page when signed out. The
  /// AuthProvider rebuilds this widget on login, so no navigation is needed.
  Widget _buildLoginView(BuildContext context) {
    return const LoginPage(navigateOnSuccess: false);
  }
}

/// The tinted square behind each settings-row glyph. Gives the rows a
/// consistent left margin and keeps the icons from floating in whitespace.
class _RowIcon extends StatelessWidget {
  const _RowIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Icon(icon, size: 18, color: AppColors.iconPrimary),
    );
  }
}
