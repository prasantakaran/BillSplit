import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/showcase_keys.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/show_case_widget.dart';

class SaveBillBar extends StatelessWidget {
  const SaveBillBar({super.key, required this.isSaving, required this.onSave});

  final ValueListenable<bool> isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.lightSurface,
        border: Border(top: BorderSide(color: AppColors.lightBorder)),
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: isSaving,
        builder: (context, saving, _) => AppShowcase(
          showcaseKey: ShowcaseKeys.resultsSaveButton,
          group: ShowcaseKeys.resultsGroup,
          title: 'Save the Bill',
          description:
              'Save this split to your history so you can revisit '
              'it anytime.',
          icon: Icons.check_circle_outline,
          child: AppButton(
            label: 'Save Bill',
            icon: Icons.check_circle_outline,
            isLoading: saving,
            onPressed: onSave,
          ),
        ),
      ),
    );
  }
}
