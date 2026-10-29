import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/state_view.dart';
import '../home/widgets/meal_card.dart';
import 'provider/favorites_provider.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    // Re-subscribe whenever the tab is opened so a sign-in or a dropped
    // connection from a previous visit is picked up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoritesProvider>().loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FavoritesProvider>();
    final count = provider.favorites.length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppTheme.spaceLg,
        title: const Text('Favorites'),
        actions: [
          if (count > 0) ...[
            Center(
              child: Text(
                count == 1 ? '1 meal' : '$count meals',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _showClearDialog(context),
              tooltip: 'Clear all',
              icon: Icon(CupertinoIcons.trash, color: AppColors.error),
            ),
            const SizedBox(width: AppTheme.spaceSm),
          ],
        ],
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(FavoritesProvider provider) {
    // Signed out is not the same as "no favorites" — point at the fix.
    if (!provider.isSignedIn) {
      return StateView.empty(
        icon: CupertinoIcons.person_crop_circle,
        title: 'Sign in to see favorites',
        message: 'Your saved meals are tied to your account.',
        actionLabel: 'Sign in',
        onAction: () => Navigator.pushNamed(context, '/login'),
      );
    }

    if (provider.isLoading && provider.favorites.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.hasBlockingError) {
      return StateView.error(
        error: provider.failure,
        onRetry: provider.retry,
      );
    }

    if (provider.favorites.isEmpty) {
      return const StateView.empty(
        icon: CupertinoIcons.heart,
        title: 'No favorites yet',
        message: 'Tap the heart on any meal and it will show up here.',
      );
    }

    return Column(
      children: [
        if (provider.hasError)
          OfflineNotice(
            message: provider.failure!.isConnectivityIssue
                ? "You're offline — showing saved favorites."
                : provider.failure!.message,
            onRetry: provider.retry,
          ),
        Expanded(
          // A real grid rather than a ListView of hand-paired rows: the
          // max-extent delegate decides the column count from the available
          // width, so wide phones and tablets get three or four columns
          // instead of two stretched ones, and the last row is not padded
          // out with an empty placeholder.
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMd,
              AppTheme.spaceMd,
              AppTheme.spaceMd,
              AppTheme.spaceLg,
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: 304,
              crossAxisSpacing: AppTheme.spaceMd,
              mainAxisSpacing: AppTheme.spaceMd,
            ),
            itemCount: provider.favorites.length,
            itemBuilder: (context, index) {
              final meal = provider.favorites[index];
              return MealCard(key: ValueKey(meal.id), meal: meal);
            },
          ),
        ),
      ],
    );
  }

  void _showClearDialog(BuildContext context) {
    Haptics.tap();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear favorites'),
        content: const Text('Are you sure you want to remove all items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Haptics.warning();
              final provider = context.read<FavoritesProvider>();
              Navigator.pop(dialogContext);

              try {
                await provider.clearFavorites();
              } catch (e) {
                debugPrint(
                  'Failed to clear favorites: ${AppException.from(e).message}',
                );
              }
            },
            child: const Text(
              'Clear all',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
