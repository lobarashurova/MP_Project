import 'package:flutter/material.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/constants/app_text_styles.dart';
import 'package:xurmo/core/localization/app_strings.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Widget _card(BuildContext context, IconData icon, String title, Widget body) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Not const and not Colors.black54: the body copy has to follow the
    // theme, or it turns invisible on the dark background.
    final bodyStyle = TextStyle(
      fontSize: 15,
      height: 1.5,
      color: AppColors.textSecondary,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.tr('about_title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Xurmo',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${context.tr('version')} 1.0.0', style: bodyStyle),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _card(
              context,
              Icons.info,
              context.tr('about_xurmo'),
              Text(context.tr('about_xurmo_text'), style: bodyStyle),
            ),
            _card(
              context,
              Icons.menu_book,
              context.tr('academic_project'),
              Text(context.tr('academic_text'), style: bodyStyle),
            ),
            _card(
              context,
              Icons.build,
              context.tr('technologies'),
              Text(
                '• Flutter & Dart\n• Firebase\n• Material Design\n• Provider State Management',
                style: bodyStyle.copyWith(height: 1.6),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          context.tr('made_in'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('rights'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}