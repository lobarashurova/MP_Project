import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/widgets/state_view.dart';
import 'package:xurmo/data/models/meal_model.dart';
import 'package:xurmo/presentation/home/providers/home_provider.dart';
import 'package:xurmo/presentation/home/widgets/category_bar.dart';
import 'package:xurmo/presentation/home/widgets/meal_card.dart';
import 'package:xurmo/core/translation/translated_text.dart';

enum _Sort { none, priceLow, priceHigh }

class CategoryPage extends StatefulWidget {
  final String initialCategory;

  const CategoryPage({super.key, required this.initialCategory});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late String _category;
  final _barScroll = ScrollController();
  final _searchController = TextEditingController();
  String _query = '';
  _Sort _sort = _Sort.none;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  void dispose() {
    _barScroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<MealModel> _visibleMeals(HomeProvider provider) {
    final q = _query.trim().toLowerCase();
    final meals = provider
        .getProductsByCategory(_category)
        .where((m) => q.isEmpty || m.name.toLowerCase().contains(q))
        .toList();

    switch (_sort) {
      case _Sort.priceLow:
        meals.sort((a, b) => a.price.compareTo(b.price));
        break;
      case _Sort.priceHigh:
        meals.sort((a, b) => b.price.compareTo(a.price));
        break;
      case _Sort.none:
        break;
    }
    return meals;
  }

  Widget _sortChip(String label, _Sort value) {
    final selected = _sort == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => setState(() => _sort = selected ? _Sort.none : value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: TranslatedText(_category == 'All' ? 'All dishes' : _category),
      ),
      body: Consumer<HomeProvider>(
        builder: (context, provider, _) {
          final meals = _visibleMeals(provider);
          final rowCount = (meals.length / 2).ceil();

          return Column(
            children: [
              const SizedBox(height: 8),
              CategoryBar(
                categories: provider.categories,
                selectedCategory: _category,
                scrollController: _barScroll,
                onCategoryTap: (c) => setState(() => _category = c),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search in this category',
                    prefixIcon: const Icon(CupertinoIcons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _sortChip('Price: low to high', _Sort.priceLow),
                    _sortChip('Price: high to low', _Sort.priceHigh),
                  ],
                ),
              ),
              Expanded(
                child: meals.isEmpty
                    ? const StateView.empty(
                  icon: CupertinoIcons.search,
                  title: 'No dishes found',
                  message: 'Try another category or clear the search.',
                )
                    : ListView.builder(
                  itemCount: rowCount,
                  itemBuilder: (context, row) {
                    final left = meals[row * 2];
                    final right =
                    row * 2 + 1 < meals.length ? meals[row * 2 + 1] : null;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(child: MealCard(meal: left)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: right != null
                                ? MealCard(meal: right)
                                : const SizedBox(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
