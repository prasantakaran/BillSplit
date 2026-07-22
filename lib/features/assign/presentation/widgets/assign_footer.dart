import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/showcase_keys.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/show_case_widget.dart';

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
          AppShowcase(
            showcaseKey: ShowcaseKeys.assignCalculateButton,
            group: ShowcaseKeys.assignGroup,
            title: 'Calculate Split',
            description: 'Once every item is assigned, tap here to see who '
                'owes what.',
            icon: Icons.calculate_outlined,
            child: AppButton(
              label: 'Calculate Split',
              trailingIcon: Icons.arrow_forward,
              onPressed: onCalculate,
            ),
          ),
        ],
      ),
    );
  }
}
