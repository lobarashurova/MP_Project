import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';
import 'package:xurmo/core/widgets/state_view.dart';
import 'package:xurmo/data/models/meal_model.dart';
import 'package:xurmo/presentation/home/providers/home_provider.dart';
import 'package:xurmo/presentation/home/widgets/meal_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  HomeProvider? _homeProvider;
  List<MealModel> _searchableMeals = [];
  List<MealModel> _filteredMeals = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<HomeProvider>();
    if (identical(provider, _homeProvider)) return;

    _homeProvider?.removeListener(_onMealsChanged);
    _homeProvider = provider..addListener(_onMealsChanged);
    _searchableMeals = List.of(provider.meals);
    _filteredMeals = _findLocalMatches(_searchableMeals, _query);
  }

  @override
  void dispose() {
    _homeProvider?.removeListener(_onMealsChanged);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _query = query;
      _filteredMeals = _findLocalMatches(_searchableMeals, query);
    });
  }

  void _onMealsChanged() {
    final provider = _homeProvider;
    if (provider == null || !mounted) return;

    setState(() {
      _searchableMeals = List.of(provider.meals);
      _filteredMeals = _findLocalMatches(_searchableMeals, _query);
    });
  }

  List<MealModel> _findLocalMatches(List<MealModel> meals, String query) {
    if (query.isEmpty) return [];

    final queryWords = query.toLowerCase().split(RegExp(r'\s+'));
    return meals.where((meal) {
      final searchableText = [
        meal.name,
        meal.category,
        meal.description,
        meal.area,
        ...meal.ingredients,
      ].join(' ').toLowerCase();
      return queryWords.every(searchableText.contains);
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
                      onPressed: _searchController.clear,
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

    if (_filteredMeals.isEmpty) {
      return StateView.empty(
        icon: CupertinoIcons.doc_text_search,
        title: 'No results found',
        message:
            'We could not find anything for "${_searchController.text.trim()}". '
            'Try a different dish, ingredient, category or cuisine.',
        actionLabel: 'Clear search',
        onAction: _searchController.clear,
      );
    }

    return Column(
      children: [
        if (provider.isShowingStaleData)
          OfflineNotice(
            message: provider.isOffline
                ? "You're offline — showing saved meals where possible."
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
            itemCount: _filteredMeals.length,
            itemBuilder: (context, index) {
              return MealCard(meal: _filteredMeals[index]);
            },
          ),
        ),
      ],
    );
  }
}
