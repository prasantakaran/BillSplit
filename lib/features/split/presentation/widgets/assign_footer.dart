import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';

class AssignFooter extends StatelessWidget {
  const AssignFooter({
    super.key,
    required this.assignedCount,
    required this.totalCount,
    required this.onCalculate,
  });

  final int assignedCount;
  final int totalCount;
  final VoidCallback? onCalculate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.lightSurface,
        border: Border(top: BorderSide(color: AppColors.lightBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$assignedCount of $totalCount items assigned',
            style: const TextStyle(
              color: AppColors.lightTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Calculate Split',
            trailingIcon: Icons.arrow_forward,
            onPressed: onCalculate,
          ),
        ],
      ),
    );
  }
}
