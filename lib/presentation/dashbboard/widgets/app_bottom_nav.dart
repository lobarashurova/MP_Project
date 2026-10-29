import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../basket/cart.dart';

/// One tab in the bottom navigation bar.
class NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// When true the tab shows a badge with the current basket quantity.
  final bool showsCartBadge;

  const NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.showsCartBadge = false,
  });
}

/// A floating bottom navigation bar.
///
/// The selected tab expands into a labelled pill while the others stay as
/// icons, so the bar never needs to shrink text to fit four labels. The
/// basket tab carries a live quantity badge — that badge is now the feedback
/// for adding an item, which is why the old "added to basket" toasts could go.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavDestination> destinations;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: AppTheme.spaceMd,
        right: AppTheme.spaceMd,
        top: AppTheme.spaceSm,
        // Sit clear of the home indicator without stranding the bar when a
        // device has no inset at all.
        bottom: bottomInset > 0 ? bottomInset : AppTheme.spaceMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < destinations.length; i++)
            _NavItem(
              destination: destinations[i],
              isSelected: i == currentIndex,
              onTap: () {
                if (i == currentIndex) return;
                Haptics.selection();
                onDestinationSelected(i);
              },
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.iconSecondary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        splashColor: AppColors.primaryTint,
        highlightColor: AppColors.primarySoft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? AppTheme.spaceMd : AppTheme.spaceSm + 2,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NavIcon(
                destination: destination,
                isSelected: isSelected,
                color: color,
              ),
              // Animate the label's width so the pill grows smoothly instead
              // of the row snapping to a new layout.
              ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  widthFactor: isSelected ? 1 : 0,
                  // Without an explicit heightFactor an Align with only a
                  // widthFactor grows to the full height it is offered, which
                  // would stretch the bar over the whole screen.
                  heightFactor: 1,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: isSelected ? 1 : 0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppTheme.spaceSm),
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tab icon, wrapped in a badge when the destination asks for one.
class _NavIcon extends StatelessWidget {
  final NavDestination destination;
  final bool isSelected;
  final Color color;

  const _NavIcon({
    required this.destination,
    required this.isSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final icon = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder:
          (child, animation) => ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
      child: Icon(
        isSelected ? destination.activeIcon : destination.icon,
        key: ValueKey<bool>(isSelected),
        color: color,
        size: 24,
      ),
    );

    if (!destination.showsCartBadge) return icon;

    return ValueListenableBuilder<int>(
      valueListenable: Cart.instance.notifier,
      builder: (context, _, child) {
        final count = Cart.instance.totalQuantity;
        return _CartBadge(count: count, child: child!);
      },
      child: icon,
    );
  }
}

/// A count badge that scales in when the basket stops being empty.
class _CartBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const _CartBadge({required this.count, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -6,
          right: -8,
          child: ExcludeSemantics(
            excluding: count == 0,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              scale: count > 0 ? 1 : 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  // Keeps the badge legible where it overlaps the glyph.
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
