import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:xurmo/core/constants/app_colors.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.iconPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppColors.shadow.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.bag_fill, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Xurmo', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  const Text('Version 1.0.0', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              icon: CupertinoIcons.info_circle_fill,
              title: 'About Xurmo',
              content: 'Xurmo is a homemade food delivery platform connecting food lovers with talented home chefs.',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: CupertinoIcons.book_fill,
              title: 'Academic Project',
              content: 'Developed as part of Mobile Programming course at New Uzbekistan University using Flutter and Firebase.',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: CupertinoIcons.hammer_fill,
              title: 'Technologies',
              content: '• Flutter & Dart\n• Firebase\n• Material Design\n• Provider State Management',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.heart_fill, color: AppColors.error, size: 20),
                      SizedBox(width: 8),
                      Text('Made in Tashkent', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('© 2025 Xurmo. All rights reserved.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.shadow.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(color: AppColors.textSecondary, height: 1.6)),
        ],
      ),
    );
  }
}