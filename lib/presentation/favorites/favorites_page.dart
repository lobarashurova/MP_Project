import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/errors/app_exception.dart';
import '../../core/widgets/state_view.dart';
import '../../presentation/favorites/provider/favorites_provider.dart';
import '../../presentation/home/widgets/meal_card.dart';

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
    final favorites = provider.favorites;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Favorites',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.iconPrimary,
          ),
        ),
        actions: [
          if (favorites.isNotEmpty)
            IconButton(
              onPressed: () => _showClearDialog(context),
              icon: const Icon(CupertinoIcons.trash, color: AppColors.error),
            ),
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
        title: 'No Favorites Yet',
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
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.63,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: provider.favorites.length,
            itemBuilder: (context, index) {
              return MealCard(meal: provider.favorites[index]);
            },
          ),
        ),
      ],
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Favorites'),
        content: const Text('Are you sure you want to remove all items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              final provider = context.read<FavoritesProvider>();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);

              try {
                await provider.clearFavorites();
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      AppException.from(e).message,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
