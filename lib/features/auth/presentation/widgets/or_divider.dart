import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.lightBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: AppColors.lightTextSecondary.withValues(alpha: 0.9),
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.lightBorder)),
      ],
    );
  }
}
