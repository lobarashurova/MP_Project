import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';

/// A surface panel: the one shape content sits on across the app.
///
/// Every screen used to re-declare the same `BoxDecoration` with its own
/// radius and its own hand-rolled shadow, which is why no two cards matched.
/// This takes the radius and shadow from [AppTheme] so they stay in step, in
/// either theme.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spaceMd),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.radius = AppTheme.radiusLarge,
    this.tinted = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double radius;

  /// Draws the card on the warm brand tint instead of the plain surface, for
  /// panels that should read as highlighted rather than neutral.
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tinted ? AppColors.primarySoft : AppColors.cardBackground,
          borderRadius: borderRadius,
          boxShadow: AppTheme.cardShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: borderRadius,
          // Clipped so the ripple follows the card's corners rather than
          // washing over them.
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    Haptics.tap();
                    onTap!();
                  },
            borderRadius: borderRadius,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// A labelled group of rows on a single [AppCard] — the pattern the profile
/// and settings screens are built from.
class AppSection extends StatelessWidget {
  const AppSection({
    super.key,
    required this.title,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
  });

  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppTheme.spaceXs,
              bottom: AppTheme.spaceSm + 2,
            ),
            child: Text(
              title.toUpperCase(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: _withDividers(children)),
          ),
        ],
      ),
    );
  }

  /// Hairlines between rows, but never above the first or below the last,
  /// where they would collide with the card's rounded corners.
  List<Widget> _withDividers(List<Widget> rows) {
    final out = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      out.add(rows[i]);
      if (i != rows.length - 1) {
        out.add(Padding(
          padding: const EdgeInsets.only(left: 54),
          child: Divider(height: 1, color: AppColors.divider),
        ));
      }
    }
    return out;
  }
}
