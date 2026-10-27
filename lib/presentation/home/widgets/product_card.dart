import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/utils/currency_formatter.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';
import 'package:xurmo/data/models/meal_model.dart';
import 'package:xurmo/presentation/basket/cart.dart';

class ProductCard extends StatelessWidget {
  final MealModel product;

  const ProductCard({super.key, required this.product});

  Widget _imagePlaceholder() {
    return Center(
      child: Icon(
        CupertinoIcons.cube_box_fill,
        size: 48,
        color: AppColors.primary.withOpacity(0.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: product.imageUrl.isEmpty
                ? _imagePlaceholder()
                : Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    // A broken or unreachable image must not leave a blank
                    // card or throw up a red error box.
                    errorBuilder: (context, error, stackTrace) =>
                        _imagePlaceholder(),
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : _imagePlaceholder(),
                  ),
          ),

          // Product details
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  product.name,
                  style: AppTextStyles.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Rating
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.star_fill,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product.rating.toStringAsFixed(1),
                      style: AppTextStyles.ratingSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Price + Add button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatSom(product.price),
                      style: AppTextStyles.productPrice,
                    ),
                    GestureDetector(
                      onTap: () {
                        Cart.instance.add(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${product.name} added to basket!',
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: AppColors.primary,
                            duration: const Duration(milliseconds: 700),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          CupertinoIcons.add,
                          size: 16,
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
