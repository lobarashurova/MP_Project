import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';
import 'package:xurmo/data/mock/mock_products.dart';
import 'package:xurmo/data/models/product_model.dart';
import 'package:xurmo/presentation/home/widgets/banner_widget.dart';
import 'package:xurmo/presentation/home/widgets/product_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ItemScrollController _itemScrollController;
  late ItemPositionsListener _itemPositionsListener;
  String _selectedCategory = 'All';
  String _visibleCategory = 'All';
  bool _isBarSticky = false;
  late Map<String, int> _categoryStartIndex;
  late List<String> _allCategories;
  late ScrollController _categoryScrollController;


  @override
  void initState() {
    super.initState();
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();
    _categoryScrollController = ScrollController();
    _initializeCategoryIndices();
    _itemPositionsListener.itemPositions.addListener(_onScroll);
  }


  void _initializeCategoryIndices() {
    _allCategories = ['All', ...MockProducts.categories];
    _categoryStartIndex = {};

    const fixedWidgetsCount = 6; // everything before products
    int currentIndex = fixedWidgetsCount;

    _categoryStartIndex['All'] = currentIndex;

    for (final category in MockProducts.categories) {
      final products = MockProducts.getProductsByCategory(category);

      // Calculate number of rows instead of number of products
      final rows = (products.length / 2).ceil();

      _categoryStartIndex[category] = currentIndex;
      currentIndex += rows;
    }
  }

  void _scrollCategoryBarTo(int index) {
    // Width estimation of each chip (~130–150 px)
    const chipWidth = 80.0;
    const spacing = 12.0;
    const totalChip = chipWidth + spacing;

    final targetOffset = index * totalChip;

    // Scroll to position smoothly
    _categoryScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }


  void _onScroll() {
    if (_itemPositionsListener.itemPositions.value.isEmpty) return;

    final visibleIndices =
    _itemPositionsListener.itemPositions.value.map((e) => e.index).toList();
    final firstVisibleIndex = visibleIndices.isNotEmpty ? visibleIndices.first : 0;

    // Check if category bar (index 5) is visible - if not, make it sticky
    final isCategoryBarVisible = visibleIndices.contains(5);
    if (_isBarSticky != !isCategoryBarVisible) {
      setState(() {
        _isBarSticky = !isCategoryBarVisible;
      });
    }

    // Determine which category is currently visible
    String currentCategory = 'All';
    _categoryStartIndex.forEach((category, startIndex) {
      if (firstVisibleIndex >= startIndex) {
        currentCategory = category;
      }
    });

    // Auto-scroll category bar when category changes
    final index = _allCategories.indexOf(currentCategory);
    if (index != -1) {
      _scrollCategoryBarTo(index);
    }

    if (_visibleCategory != currentCategory) {
      setState(() {
        _visibleCategory = currentCategory;
      });
    }
  }

  void _scrollToCategory(String category) {
    final targetIndex = _categoryStartIndex[category] ?? 0;
    _itemScrollController.scrollTo(
      index: targetIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
    setState(() {
      _selectedCategory = category;
    });
  }

  List<ProductModel> get _allProducts {
    final allProds = <ProductModel>[];
    for (final category in MockProducts.categories) {
      allProds.addAll(MockProducts.getProductsByCategory(category));
    }
    return allProds;
  }

  Widget _buildCategoryBar() {
    return Container(
      color: AppColors.background,
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          controller: _categoryScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
          itemCount: _allCategories.length,
          itemBuilder: (context, index) {
            final category = _allCategories[index];
            final isSelected = _visibleCategory == category;

            return GestureDetector(
              onTap: () => _scrollToCategory(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    category,
                    style: AppTextStyles.categoryChip.copyWith(
                      color: isSelected
                          ? AppColors.surface
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
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
      body: Stack(
        children: [
          // Main scrollable content
          SafeArea(
            child: ScrollablePositionedList.builder(
              itemScrollController: _itemScrollController,
              itemPositionsListener: _itemPositionsListener,
              itemCount: _allProducts.length + 6, // +6 for fixed widgets
              itemBuilder: (context, index) {
                // Header with greeting
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, User',
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

                // Search Field
                if (index == 1) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search for food...',
                          hintStyle: AppTextStyles.hint,
                          prefixIcon: Icon(
                            CupertinoIcons.search,
                            color: AppColors.iconSecondary,
                          ),
                          suffixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              CupertinoIcons.slider_horizontal_3,
                              color: AppColors.surface,
                              size: 20,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // SizedBox after search
                if (index == 2) {
                  return const SizedBox(height: 24);
                }

                // Banner
                if (index == 3) {
                  return const BannerWidget();
                }

                // SizedBox after banner
                if (index == 4) {
                  return const SizedBox(height: 24);
                }

                // Category Bar (scrollable, not sticky yet)
                if (index == 5) {
                  return _buildCategoryBar();
                }

                // Products Grid (2 columns)
                // Products Grid (2-column, row-based)
                if (index >= 6) {
                  final rowIndex = index - 6;
                  final leftIndex = rowIndex * 2;
                  final rightIndex = leftIndex + 1;

                  if (leftIndex >= _allProducts.length) {
                    return const SizedBox.shrink();
                  }

                  final leftProduct = _allProducts[leftIndex];
                  final rightProduct = rightIndex < _allProducts.length
                      ? _allProducts[rightIndex]
                      : null;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        // Left card
                        Expanded(
                          child: ProductCard(product: leftProduct),
                        ),

                        const SizedBox(width: 16),

                        // Right card (or empty box if odd number)
                        Expanded(
                          child: rightProduct != null
                              ? ProductCard(product: rightProduct)
                              : const SizedBox(),
                        ),
                      ],
                    ),
                  );
                }

                return SizedBox.shrink();
              },
            ),
          ),

          // Sticky Category Bar (appears when scrolled past the original)
          if (_isBarSticky)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: _buildCategoryBar(),
              ),
            ),
        ],
      ),
    );
  }
}