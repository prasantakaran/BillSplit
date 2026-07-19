import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ScanPlaceholder extends StatelessWidget {
  const ScanPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: AppColors.brandBlue.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            const Text(
              'Snap or pick a photo of the bill',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Keep the bill flat and well lit for the best results.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
