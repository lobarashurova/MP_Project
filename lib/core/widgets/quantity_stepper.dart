import 'package:flutter/cupertino.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';

/// The −/count/+ control used on meal cards and basket rows.
///
/// It existed three times with three different circle sizes and icon colours;
/// this is the single version.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    this.compact = false,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  /// Smaller buttons for dense rows such as the basket list.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final diameter = compact ? 28.0 : 32.0;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: CupertinoIcons.minus,
            diameter: diameter,
            // Grey rather than brand orange: stepping down is the recessive
            // action of the pair.
            color: AppColors.textSecondary,
            onTap: onDecrease,
          ),
          Container(
            constraints: BoxConstraints(minWidth: diameter),
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _StepButton(
            icon: CupertinoIcons.plus,
            diameter: diameter,
            color: AppColors.primary,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.diameter,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final double diameter;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.change();
        onTap();
      },
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: AppTheme.cardShadow,
        ),
        child: Icon(icon, size: diameter * 0.45, color: color),
      ),
    );
  }
}
