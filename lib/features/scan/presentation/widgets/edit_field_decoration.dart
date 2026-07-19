import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

InputDecoration editFieldDecoration({
  required String hint,
  String? prefixText,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.lightTextSecondary),
    prefixText: prefixText,
    isDense: true,
    filled: true,
    fillColor: AppColors.lightSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.lightBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
    ),
  );
}
