import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/constants/app_pricing.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';
import 'package:xurmo/core/localization/app_strings.dart';
import 'package:xurmo/core/theme/app_theme.dart';
import 'package:xurmo/core/utils/haptics.dart';
import 'package:xurmo/core/utils/money.dart';
import 'package:xurmo/core/widgets/app_card.dart';
import 'package:xurmo/core/widgets/state_view.dart';
import 'package:xurmo/presentation/basket/cart.dart';
import 'package:xurmo/presentation/home/widgets/cart_item_card.dart';

import '../orders/checkout_page.dart';

class BasketPage extends StatefulWidget {
  const BasketPage({super.key});

  @override
  State<BasketPage> createState() => _BasketPageState();
}

class _BasketPageState extends State<BasketPage> {
  @override
  void initState() {
    super.initState();
    Cart.instance.notifier.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    // Without this the listener outlives the page and calls setState on a
    // disposed State every time the cart changes.
    Cart.instance.notifier.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = Cart.instance.items;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('your_basket')),
        titleSpacing: AppTheme.spaceLg,
        actions: [
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spaceLg),
              child: Center(
                child: Text(
                  '${Cart.instance.totalItems} ${context.tr('items')}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: items.isEmpty
          ? StateView.empty(
              icon: CupertinoIcons.cart,
              title: context.tr('basket_empty'),
              message: context.tr('basket_empty_msg'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(
                      top: AppTheme.spaceMd,
                      bottom: AppTheme.spaceLg,
                    ),
                    children: [
                      const _DeliveryStrip(),
                      const SizedBox(height: AppTheme.spaceMd),
                      for (final item in items)
                        CartItemCard(key: ValueKey(item.product.id), cartItem: item),
                    ],
                  ),
                ),
                const _OrderSummary(),
              ],
            ),
    );
  }
}

/// The two delivery facts shown above the basket contents. One tile widget
/// rather than the same forty lines written out twice.
class _DeliveryStrip extends StatelessWidget {
  const _DeliveryStrip();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: AppTheme.spaceSm + 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: _Fact(
              icon: CupertinoIcons.clock,
              label: context.tr('delivery_time'),
              value: AppPricing.deliveryTime,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: AppColors.divider,
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSm),
          ),
          Expanded(
            child: _Fact(
              icon: CupertinoIcons.gift,
              label: context.tr('free_item_over'),
              value: formatSum(AppPricing.promoThreshold),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 19),
        ),
        const SizedBox(width: AppTheme.spaceSm + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.subtitleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The pinned totals panel. It floats above the list with the same shadow the
/// nav bar uses, so the two read as one layer.
class _OrderSummary extends StatelessWidget {
  const _OrderSummary();

  @override
  Widget build(BuildContext context) {
    final cart = Cart.instance;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppTheme.floatingShadow,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceLg,
            AppTheme.spaceMd,
            AppTheme.spaceLg,
            AppTheme.spaceMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Line(
                label: context.tr('subtotal'),
                value: formatSum(cart.subtotal),
              ),
              // Without this row the panel read "100 000 + 15 000 = 85 000":
              // the promo was being applied to the total but never itemised.
              if (cart.discount > 0) ...[
                const SizedBox(height: AppTheme.spaceSm),
                _Line(
                  label:
                      '${context.tr('discount')} (${AppPricing.promoDiscountPercent}%)',
                  value: '-${formatSum(cart.discount)}',
                  valueColor: AppColors.success,
                ),
              ],
              const SizedBox(height: AppTheme.spaceSm),
              _Line(
                label: context.tr('delivery_fee'),
                value: formatSum(cart.deliveryFee),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spaceSm + 4,
                ),
                child: Divider(height: 1, color: AppColors.divider),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('total'),
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    formatSum(cart.totalPrice),
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMd),
              // Unstyled on purpose: the elevated button theme already
              // carries the height, radius and colours.
              ElevatedButton(
                onPressed: () {
                  Haptics.tap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckoutPage()),
                  );
                },
                child: Text(context.tr('order_now')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
