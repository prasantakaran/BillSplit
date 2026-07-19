import 'package:flutter/material.dart';

import '../../../../core/models/settlement.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

class SettlementCard extends StatelessWidget {
  const SettlementCard({
    super.key,
    required this.settlement,
    required this.onShare,
    required this.onPreviewLink,
  });

  final Settlement settlement;
  final VoidCallback onShare;
  final VoidCallback onPreviewLink;

  @override
  Widget build(BuildContext context) {
    final String initial = settlement.friendName.isEmpty
        ? '?'
        : settlement.friendName[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.brandBlue.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settlement.friendName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  'Items ${CurrencyFormatter.format(settlement.itemsTotal)}'
                  ' + tax ${CurrencyFormatter.format(settlement.taxShare)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(settlement.totalOwed),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandNavy,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Open in UPI app',
            icon: const Icon(Icons.open_in_new, color: AppColors.brandBlue),
            onPressed: onPreviewLink,
          ),
          IconButton(
            tooltip: 'Share payment request',
            icon: const Icon(Icons.share_outlined, color: AppColors.brandTeal),
            onPressed: onShare,
          ),
        ],
      ),
    );
  }
}
