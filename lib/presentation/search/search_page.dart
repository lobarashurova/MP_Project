import 'dart:async';

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
  List<MealModel> _filteredMeals = [];
  Timer? _searchDebounce;
  int _searchRequestId = 0;
  String _query = '';
  bool _isLoading = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    final provider = context.read<HomeProvider>();
    final requestId = ++_searchRequestId;
    _searchDebounce?.cancel();

    setState(() {
      _query = query.toLowerCase();
      _isLoading = query.isNotEmpty;
      _searchError = null;
      _filteredMeals = _findLocalMatches(provider.meals, query);
    });

    if (query.isEmpty) return;

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final remoteMeals = await provider.searchMeals(query);
        if (!mounted || requestId != _searchRequestId) return;

        final mealsById = <String, MealModel>{
          for (final meal in _filteredMeals) meal.id: meal,
          for (final meal in remoteMeals) meal.id: meal,
        };
        setState(() {
          _filteredMeals = mealsById.values.toList();
          _isLoading = false;
        });
      } catch (error) {
        if (!mounted || requestId != _searchRequestId) return;
        debugPrint('Meal search failed: $error');
        setState(() {
          _isLoading = false;
          _searchError =
              'Online search failed. Check your connection and try again.';
        });
      }
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

    if (_filteredMeals.isEmpty && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_filteredMeals.isEmpty && _searchError != null) {
      return StateView.error(
        error: _searchError,
        onRetry: () => _onSearchChanged(),
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
        if (_isLoading)
          const LinearProgressIndicator(
            color: AppColors.primary,
            minHeight: 2,
          ),
        if (_searchError != null)
          OfflineNotice(message: _searchError!),
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
