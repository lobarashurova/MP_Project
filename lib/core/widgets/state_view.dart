import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';
import 'package:xurmo/core/errors/app_exception.dart';
import 'package:xurmo/core/theme/app_theme.dart';
import 'package:xurmo/core/utils/haptics.dart';

/// A single, consistent way to render "there is nothing here" and
/// "something failed" screens across the app.
///
/// Use [StateView.empty] for a legitimately empty collection and
/// [StateView.error] when a load failed — the error flavour picks its own
/// icon and copy from the [AppException] type, so an offline failure never
/// reads as "no results".
class StateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accentColor;

  const StateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.accentColor = AppColors.primary,
  });

  /// An empty — but perfectly healthy — collection.
  const StateView.empty({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : accentColor = AppColors.primary;

  /// A failed load. Copy and icon are derived from [error] so offline,
  /// timeout and server failures are visibly different.
  factory StateView.error({
    Key? key,
    required Object? error,
    VoidCallback? onRetry,
    String retryLabel = 'Try again',
  }) {
    final failure = AppException.from(error);
    return StateView(
      key: key,
      icon: _iconFor(failure),
      title: failure.title,
      message: failure.message,
      actionLabel: onRetry == null ? null : retryLabel,
      onAction: onRetry,
      accentColor: AppColors.error,
    );
  }

  static IconData _iconFor(AppException error) {
    switch (error.type) {
      case AppErrorType.noConnection:
        return CupertinoIcons.wifi_slash;
      case AppErrorType.timeout:
        return CupertinoIcons.clock;
      case AppErrorType.unauthorized:
        return CupertinoIcons.lock;
      case AppErrorType.server:
      case AppErrorType.unknown:
        return CupertinoIcons.exclamationmark_triangle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceXl,
          vertical: AppTheme.spaceLg,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: accentColor),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: AppTheme.spaceSm + 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTheme.spaceLg + 4),
              // Width-constrained rather than full-bleed: the button theme
              // stretches to the full line otherwise, which looks wrong under
              // centred copy.
              ElevatedButton(
                onPressed: () {
                  Haptics.tap();
                  onAction!();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 48),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Slim inline notice for when we *do* have content to show (usually from
/// cache) but the last refresh failed. Non-blocking, unlike [StateView.error].
class OfflineNotice extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const OfflineNotice({
    super.key,
    this.message = "You're offline — showing saved items.",
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceSm,
        AppTheme.spaceMd,
        0,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSm + 4,
        vertical: AppTheme.spaceSm + 2,
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.wifi_slash,
            size: 18,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry == null
                  ? null
                  : () {
                      Haptics.tap();
                      onRetry!();
                    },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Retry',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
