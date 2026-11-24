import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/localization/app_strings.dart';
import 'package:xurmo/core/theme/app_theme.dart';
import 'package:xurmo/core/utils/haptics.dart';
import 'package:xurmo/data/models/saved_address.dart';

/// Icon that matches what the customer called the place.
IconData savedAddressIcon(String label) {
  final l = label.toLowerCase();
  if (l.contains('home') || l.contains('дом') || l.contains('uy')) {
    return CupertinoIcons.house_fill;
  }
  if (l.contains('work') || l.contains('office') || l.contains('раб') || l.contains('ish')) {
    return CupertinoIcons.briefcase_fill;
  }
  return CupertinoIcons.location_solid;
}

/// Horizontal strip of the customer's saved addresses, newest first.
///
/// One tap fills the whole delivery section, which is the point: the common
/// case at checkout is ordering to the same place as last time.
class SavedAddressPicker extends StatelessWidget {
  const SavedAddressPicker({
    super.key,
    required this.addresses,
    required this.selectedId,
    required this.onSelect,
    required this.onDelete,
    this.enabled = true,
  });

  final List<SavedAddress> addresses;
  final String? selectedId;
  final ValueChanged<SavedAddress> onSelect;
  final ValueChanged<SavedAddress> onDelete;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (addresses.isEmpty) return const SizedBox.shrink();

    // The card holds three short lines, so it has to grow with the font-size
    // setting rather than clip it.
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);

    return SizedBox(
      height: 112 * scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.zero,
        itemCount: addresses.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spaceSm + 2),
        itemBuilder: (context, index) {
          final address = addresses[index];
          return _SavedAddressCard(
            width: 208 * scale,
            address: address,
            isSelected: address.id == selectedId,
            onTap: enabled ? () => onSelect(address) : null,
            onDelete: enabled ? () => onDelete(address) : null,
          );
        },
      ),
    );
  }
}

class _SavedAddressCard extends StatelessWidget {
  const _SavedAddressCard({
    required this.width,
    required this.address,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  final double width;
  final SavedAddress address;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusMedium);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: width,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primarySoft : AppColors.cardBackground,
        borderRadius: radius,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap == null
              ? null
              : () {
                  Haptics.selection();
                  onTap!();
                },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceSm + 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        savedAddressIcon(address.label),
                        size: 15,
                        color: isSelected ? AppColors.onPrimary : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSm),
                    Expanded(
                      child: Text(
                        address.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(CupertinoIcons.checkmark_alt_circle_fill,
                          size: 18, color: AppColors.primary)
                    else
                      // Removing lives on the card itself so the list needs
                      // no separate manage screen.
                      _DeleteButton(onPressed: onDelete, label: address.label),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Expanded(
                  child: Text(
                    address.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (address.hasPin)
                  Row(
                    children: [
                      Icon(CupertinoIcons.map_pin_ellipse,
                          size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          context.tr('pinned_on_map'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onPressed, required this.label});

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(CupertinoIcons.xmark, size: 13),
      color: AppColors.iconSecondary,
      tooltip: context.tr('remove_named').replaceAll('{label}', label),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
    );
  }
}

/// The row under the address field that offers to keep the address, with the
/// label chips revealed only once the switch is on.
class SaveAddressBar extends StatelessWidget {
  const SaveAddressBar({
    super.key,
    required this.isOn,
    required this.label,
    required this.labels,
    required this.onChanged,
    required this.onLabelChanged,
    this.enabled = true,
  });

  final bool isOn;
  final String label;

  /// The names offered as chips, already in the current language.
  final List<String> labels;
  final ValueChanged<bool> onChanged;
  final ValueChanged<String> onLabelChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMd, AppTheme.spaceSm, AppTheme.spaceSm, AppTheme.spaceSm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: isOn ? AppColors.primary : AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.bookmark, size: 18, color: AppColors.primary),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: Text(
                  context.tr('save_this_address'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Plain Switch: its colours come from AppTheme.switchTheme, the
              // same as the settings toggles.
              Switch(
                value: isOn,
                onChanged: enabled
                    ? (value) {
                        Haptics.change();
                        onChanged(value);
                      }
                    : null,
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: isOn
                ? Padding(
                    padding: const EdgeInsets.only(
                        top: AppTheme.spaceXs, bottom: AppTheme.spaceXs),
                    // Wrap, not Row: at the larger font-size settings three
                    // chips do not fit one line on a narrow phone.
                    child: Wrap(
                      spacing: AppTheme.spaceSm,
                      runSpacing: AppTheme.spaceSm,
                      children: [
                        for (final suggestion in labels)
                          _LabelChip(
                            label: suggestion,
                            isSelected: suggestion == label,
                            onTap: enabled
                                ? () {
                                    Haptics.selection();
                                    onLabelChanged(suggestion);
                                  }
                                : null,
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusPill);

    return Material(
      color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                savedAddressIcon(label),
                size: 13,
                color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
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
