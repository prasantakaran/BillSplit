import 'package:flutter/material.dart';

import '../../../../core/models/tax_line.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Display-only card listing every tax/charge line detected on the bill
/// (CGST, SGST, service charge, ...). The editable Tax/GST field holds
/// their sum and stays the source of truth for the split.
class TaxBreakdown extends StatelessWidget {
  const TaxBreakdown({super.key, required this.taxLines});

  final List<TaxLine> taxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Taxes detected on bill',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          for (final TaxLine tax in taxLines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tax.label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(tax.amount),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
