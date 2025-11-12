import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';
import 'package:xurmo/data/models/product_model.dart';
import 'package:xurmo/presentation/basket/cart.dart';


class CartItemCard extends StatelessWidget {
  final CartItem cartItem;

  const CartItemCard({super.key, required this.cartItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              cartItem.product.imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),

          // Product name and price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.product.name,
                  style: AppTextStyles.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${cartItem.product.price.toStringAsFixed(2)}',
                  style: AppTextStyles.productPrice.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary, width: 1),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Cart.instance.decreaseQuantity(cartItem.product);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 4),
                    child: Icon(
                      CupertinoIcons.minus_circle,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    cartItem.quantity.toString(),
                    style: AppTextStyles.bodyLarge,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Cart.instance.increaseQuantity(cartItem.product);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 4),
                    child: Icon(
                      CupertinoIcons.add_circled_solid,
                      color: Colors.green,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
