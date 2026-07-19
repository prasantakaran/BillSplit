import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';

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
        builder: (context, saving, _) => AppButton(
          label: 'Save Bill',
          icon: Icons.check_circle_outline,
          isLoading: saving,
          onPressed: onSave,
        ),
      ),
    );
  }
}
