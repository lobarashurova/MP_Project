import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';
import 'package:xurmo/core/widgets/state_view.dart';
import 'package:xurmo/presentation/home/providers/home_provider.dart';
import 'package:xurmo/presentation/home/widgets/meal_card.dart';
import 'package:xurmo/data/models/meal_model.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query == _query) {
      // Still rebuild so the clear button appears/disappears.
      setState(() {});
      return;
    }
    setState(() => _query = query);
  }

  List<MealModel> _matches(List<MealModel> meals) {
    if (_query.isEmpty) return const [];
    return meals.where((meal) {
      return meal.name.toLowerCase().contains(_query) ||
          meal.category.toLowerCase().contains(_query) ||
          meal.area.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.iconPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search for food...',
              hintStyle: AppTextStyles.hint,
              prefixIcon: const Icon(
                CupertinoIcons.search,
                color: AppColors.iconSecondary,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        CupertinoIcons.clear_circled_solid,
                        color: AppColors.iconSecondary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(HomeProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // There is nothing loaded to search through because the menu failed to
    // load — say that, rather than pretending the search found nothing.
    if (provider.hasBlockingError) {
      return StateView.error(
        error: provider.failure,
        onRetry: provider.retry,
        retryLabel: 'Reload menu',
      );
    }

    if (provider.meals.isEmpty) {
      return StateView.empty(
        icon: CupertinoIcons.square_list,
        title: 'Nothing to search yet',
        message: 'The menu is empty right now. Try reloading it.',
        actionLabel: 'Reload menu',
        onAction: provider.retry,
      );
    }

    if (_query.isEmpty) {
      return const StateView.empty(
        icon: CupertinoIcons.search,
        title: 'Search for food',
        message: 'Start typing to find your favorite meals',
      );
    }

    final matches = _matches(provider.meals);

    if (matches.isEmpty) {
      return StateView.empty(
        icon: CupertinoIcons.doc_text_search,
        title: 'No results found',
        message:
            'We could not find anything for "${_searchController.text.trim()}". '
            'Try a different dish, category or cuisine.',
        actionLabel: 'Clear search',
        onAction: () => _searchController.clear(),
      );
    }

    return Column(
      children: [
        if (provider.isShowingStaleData)
          OfflineNotice(
            message: provider.isOffline
                ? "You're offline — searching saved meals only."
                : provider.failure!.message,
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              return MealCard(meal: matches[index]);
            },
          ),
        ),
      ],
    );
  }
}
