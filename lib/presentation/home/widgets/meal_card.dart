import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';
import 'package:xurmo/core/theme/app_theme.dart';
import 'package:xurmo/core/utils/haptics.dart';
import 'package:xurmo/data/models/meal_model.dart';
import 'package:xurmo/presentation/basket/cart.dart';
import 'package:xurmo/presentation/home/product_detail_page.dart';
import 'package:xurmo/presentation/favorites/provider/favorites_provider.dart';
import 'package:xurmo/core/utils/money.dart';
import 'package:xurmo/core/translation/translated_text.dart';

class MealCard extends StatefulWidget {
  final MealModel meal;

  const MealCard({
    super.key,
    required this.meal,
  });

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  late MealModel _product;
  int _quantity = 0;

  @override
  void initState() {
    super.initState();
    _product = widget.meal;
    _updateQuantity();
    Cart.instance.notifier.addListener(_updateQuantity);
  }
  @override
  void didUpdateWidget(covariant MealCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meal.id != widget.meal.id) {
      _product = widget.meal;
    }
  }

  @override
  void dispose() {
    Cart.instance.notifier.removeListener(_updateQuantity);
    super.dispose();
  }

  void _updateQuantity() {
    try {
      final cartItem = Cart.instance.items.firstWhere(
            (item) => item.product.id == _product.id,
      );
      if (mounted) {
        setState(() {
          _quantity = cartItem.quantity;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _quantity = 0;
        });
      }
    }
  }

  void _addToCart() {
    Haptics.success();
    Cart.instance.add(_product);
  }

  void _increaseQuantity() {
    Haptics.change();
    Cart.instance.increaseQuantity(_product);
  }

  void _decreaseQuantity() {
    Haptics.change();
    Cart.instance.decreaseQuantity(_product);
  }

  void _showMessage(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? AppColors.primary,
        duration: const Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleFavorite(FavoritesProvider favProvider) async {
    // Favorites are stored per user, so tell a signed-out user what to do
    // instead of failing with a generic error.
    if (FirebaseAuth.instance.currentUser == null) {
      _showMessage('Please log in to save favorites', color: Colors.red);
      return;
    }

    final isFavorite = favProvider.isFavorite(_product.id);
    // The heart fills in immediately, so a confirmation toast would only
    // repeat what the icon already shows. Failures still need to be told.
    Haptics.tap();

    try {
      if (isFavorite) {
        await favProvider.removeFavorite(_product.id);
      } else {
        await favProvider.addFavorite(_product);
      }
    } catch (e) {
      _showMessage('Failed to update favorites', color: AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favProvider, _) {
        final isFavorite = favProvider.isFavorite(_product.id);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(meal: widget.meal),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusLarge),
                      ),
                      child: Image.network(
                        widget.meal.imageUrl,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 140,
                            color: AppColors.shadow,
                            child: Icon(
                              CupertinoIcons.photo,
                              color: AppColors.iconSecondary,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _toggleFavorite(favProvider),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Icon(
                            isFavorite
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart,
                            color: isFavorite
                                ? Colors.red
                                : AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        widget.meal.name,
                        style: AppTextStyles.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TranslatedText(
                              widget.meal.category,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TranslatedText(
                              widget.meal.area,
                              style: AppTextStyles.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.list_bullet,
                            color: AppColors.iconSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.meal.ingredients.length} ingredients',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatSum(_product.price),
                            style: AppTextStyles.productPrice,
                          ),
                          if (_quantity == 0)
                            GestureDetector(
                              onTap: _addToCart,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusSmall),
                                ),
                                child: Icon(
                                  CupertinoIcons.add,
                                  size: 18,
                                  color: AppColors.surface,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: _decreaseQuantity,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        shape: BoxShape.circle,
                                        boxShadow: AppTheme.cardShadow,
                                      ),
                                      child: Icon(
                                        CupertinoIcons.minus,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      _quantity.toString(),
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _increaseQuantity,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        shape: BoxShape.circle,
                                        boxShadow: AppTheme.cardShadow,
                                      ),
                                      child: Icon(
                                        CupertinoIcons.plus,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}