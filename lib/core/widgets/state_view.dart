import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';
import 'package:xurmo/core/errors/app_exception.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: accentColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: onAction == null
                    ? null
                    : () {
                        Haptics.tap();
                        onAction!();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  actionLabel!,
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.surface,
                  ),
                ),
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
      color: AppColors.warning.withOpacity(0.18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
