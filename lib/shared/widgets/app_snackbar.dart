import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

abstract final class AppSnackbar {
  static void show(BuildContext context, String message) {
    _show(context, message);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, backgroundColor: AppColors.negativeAmount);
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, backgroundColor: AppColors.positiveAmount);
  }

  static void _show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: backgroundColor,
          content: Text(
            message,
            style: backgroundColor == null
                ? null
                : const TextStyle(color: Colors.white),
          ),
        ),
      );
  }
}
