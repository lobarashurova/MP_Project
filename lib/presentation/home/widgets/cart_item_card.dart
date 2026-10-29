import 'package:flutter/cupertino.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';
import 'package:xurmo/core/theme/app_theme.dart';
import 'package:xurmo/core/utils/money.dart';
import 'package:xurmo/core/widgets/app_card.dart';
import 'package:xurmo/core/widgets/quantity_stepper.dart';
import 'package:xurmo/presentation/basket/cart.dart';
import 'package:xurmo/core/translation/translated_text.dart';

class CartItemCard extends StatelessWidget {
  final CartItem cartItem;

  const CartItemCard({super.key, required this.cartItem});

  @override
  Widget build(BuildContext context) {
    final product = cartItem.product;

    return AppCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: AppTheme.spaceXs + 1,
      ),
      padding: const EdgeInsets.all(AppTheme.spaceSm + 2),
      radius: AppTheme.radiusMedium,
      child: Row(
        children: [
          _Thumbnail(url: product.imageUrl),
          const SizedBox(width: AppTheme.spaceSm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TranslatedText(
                  product.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spaceXs),
                Text(
                  formatSum(product.price),
                  style: AppTextStyles.productPrice.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceSm),
          QuantityStepper(
            quantity: cartItem.quantity,
            compact: true,
            onDecrease: () => Cart.instance.decreaseQuantity(product),
            onIncrease: () => Cart.instance.increaseQuantity(product),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String url;

  static const double _size = 52;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: SizedBox(
        width: _size,
        height: _size,
        // An empty URL is checked up front: Image.network would throw on it
        // before errorBuilder ever runs.
        child: url.isEmpty
            ? const _ThumbnailPlaceholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _ThumbnailPlaceholder(),
              ),
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceAlt,
      child: Icon(
        CupertinoIcons.photo,
        size: 20,
        color: AppColors.iconSecondary,
      ),
    );
  }
}
