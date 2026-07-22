import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/models/bill.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';

class DeleteBillDialog extends StatelessWidget {
  const DeleteBillDialog({super.key, required this.bill, required this.dateLabel});

  final Bill bill;
  final String dateLabel;

  static Future<bool?> show(
    BuildContext context, {
    required Bill bill,
    required String dateLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => DeleteBillDialog(bill: bill, dateLabel: dateLabel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: AppColors.lightBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Delete bill?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '"${bill.restaurantName}" from $dateLabel will be deleted.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Delete',
                backgroundColor: AppColors.negativeAmount,
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.lightTextSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
