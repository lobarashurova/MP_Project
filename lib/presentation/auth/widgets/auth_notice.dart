import 'package:flutter/cupertino.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

/// Whether a notice reports a failure or confirms something happened.
enum AuthNoticeTone { error, success }

/// Inline banner at the top of the auth forms.
///
/// This is where auth feedback lives now that the app has no bottom toasts:
/// it stays on screen with the form that produced it instead of sliding away
/// after a few seconds, which matters most for the password reset, whose only
/// other evidence is an email that may take a minute to arrive.
class AuthNotice extends StatelessWidget {
  const AuthNotice({
    super.key,
    required this.message,
    required this.tone,
  });

  final String message;
  final AuthNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final isError = tone == AuthNoticeTone.error;
    final accent = isError ? AppColors.error : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceSm + 4),
      decoration: BoxDecoration(
        // Alpha over the page rather than a fixed tint, so the banner sits
        // correctly on both the light and the dark background.
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError
                ? CupertinoIcons.exclamationmark_circle
                : CupertinoIcons.checkmark_circle,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: AppTheme.spaceSm + 2),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
