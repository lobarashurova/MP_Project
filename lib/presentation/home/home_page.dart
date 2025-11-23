import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/presentation/home/providers/home_provider.dart';
import 'package:xurmo/presentation/home/widgets/banner_widget.dart';
import 'package:xurmo/presentation/home/widgets/category_bar.dart';
import 'package:xurmo/presentation/home/widgets/home_header.dart';
import 'package:xurmo/presentation/home/widgets/meal_card.dart';
import 'package:xurmo/presentation/home/widgets/meal_card_shimmer.dart';
import 'package:xurmo/presentation/home/widgets/search_bar_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ItemScrollController _itemScrollController;
  late ItemPositionsListener _itemPositionsListener;
  late ScrollController _categoryScrollController;
  bool _isBarSticky = false;

  @override
  void initState() {
    super.initState();
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();
    _categoryScrollController = ScrollController();
    _itemPositionsListener.itemPositions.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadMeals();
    });
  }

  void _scrollCategoryBarTo(int index) {
    const chipWidth = 80.0;
    const spacing = 12.0;
    const totalChip = chipWidth + spacing;

    final targetOffset = index * totalChip;
    _categoryScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onScroll() {
    if (_itemPositionsListener.itemPositions.value.isEmpty) return;

    final provider = context.read<HomeProvider>();
    final visibleIndices = _itemPositionsListener.itemPositions.value
        .map((e) => e.index)
        .toList();
    final firstVisibleIndex = visibleIndices.isNotEmpty ? visibleIndices.first : 0;

    final isCategoryBarVisible = visibleIndices.contains(5);
    if (_isBarSticky != !isCategoryBarVisible) {
      setState(() {
        _isBarSticky = !isCategoryBarVisible;
      });
    }

    final categoryIndices = provider.getCategoryStartIndices();
    String currentCategory = 'All';
    categoryIndices.forEach((category, startIndex) {
      if (firstVisibleIndex >= startIndex) {
        currentCategory = category;
      }
    });

    final categories = provider.categories;
    final index = categories.indexOf(currentCategory);
    if (index != -1) {
      _scrollCategoryBarTo(index);
    }

    if (provider.visibleCategory != currentCategory) {
      provider.setVisibleCategory(currentCategory);
    }
  }

  void _scrollToCategory(String category) {
    final provider = context.read<HomeProvider>();
    final categoryIndices = provider.getCategoryStartIndices();
    final targetIndex = categoryIndices[category] ?? 0;

    _itemScrollController.scrollTo(
      index: targetIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
    provider.setSelectedCategory(category);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onScroll);
    _categoryScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          final allMeals = provider.meals;
          final itemCount = provider.isLoading ? 16 : allMeals.length + 6;

          return Stack(
            children: [
              SafeArea(
                child: ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (index == 0) return const HomeHeader();
                    if (index == 1) return const SearchBarWidget();
                    if (index == 2) return const SizedBox(height: 24);
                    if (index == 3) return const BannerWidget();
                    if (index == 4) return const SizedBox(height: 24);
                    if (index == 5) {
                      return CategoryBar(
                        categories: provider.categories,
                        selectedCategory: provider.visibleCategory,
                        scrollController: _categoryScrollController,
                        onCategoryTap: _scrollToCategory,
                      );
                    }

                    if (index >= 6) {
                      final rowIndex = index - 6;
                      final leftIndex = rowIndex * 2;
                      final rightIndex = leftIndex + 1;

                      if (provider.isLoading) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Row(
                            children: const [
                              Expanded(child: MealCardShimmer()),
                              SizedBox(width: 16),
                              Expanded(child: MealCardShimmer()),
                            ],
                          ),
                        );
                      }

                      if (leftIndex >= allMeals.length) {
                        return const SizedBox.shrink();
                      }

                      final leftMeal = allMeals[leftIndex];
                      final rightMeal = rightIndex < allMeals.length
                          ? allMeals[rightIndex]
                          : null;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: MealCard(meal: leftMeal),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: rightMeal != null
                                  ? MealCard(meal: rightMeal)
                                  : const SizedBox(),
                            ),
                          ],
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
              if (_isBarSticky && !provider.isLoading)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: CategoryBar(
                      categories: provider.categories,
                      selectedCategory: provider.visibleCategory,
                      scrollController: _categoryScrollController,
                      onCategoryTap: _scrollToCategory,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
