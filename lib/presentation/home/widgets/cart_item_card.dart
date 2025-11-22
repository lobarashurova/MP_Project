import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';
import 'package:xurmo/presentation/basket/cart.dart';

class CartItemCard extends StatelessWidget {
  final CartItem cartItem;

  const CartItemCard({super.key, required this.cartItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row with product info and delete button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product name and popular badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cartItem.product.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Popular badge
                    Text(
                      'Popular',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button
              GestureDetector(
                onTap: () => Cart.instance.remove(cartItem.product),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    CupertinoIcons.trash,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Bottom row with price and quantity controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price
              Text(
                '\$${cartItem.product.price.toStringAsFixed(2)}',
                style: AppTextStyles.productPrice.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Quantity controls
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    // Minus button
                    GestureDetector(
                      onTap: () => Cart.instance.decreaseQuantity(cartItem.product),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.minus,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    
                    // Quantity
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        cartItem.quantity.toString(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    // Plus button
                    GestureDetector(
                      onTap: () => Cart.instance.increaseQuantity(cartItem.product),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.plus,
                          size: 16,
                          color: AppColors.textSecondary,
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
    );
  }
}