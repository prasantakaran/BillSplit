import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/showcase_keys.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/show_case_widget.dart';
import 'scan_bill_card.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.welcomeName,
    required this.onScanTap,
    required this.onSearchChanged,
    required this.onSeeAllTap,
  });

  final String welcomeName;
  final VoidCallback onScanTap;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSeeAllTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome,',
            style: TextStyle(fontSize: 15, color: AppColors.lightTextSecondary),
          ),
          Text(
            welcomeName.isNotEmpty
                ? welcomeName[0].toUpperCase() +
                      welcomeName.substring(1).toLowerCase()
                : '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          AppShowcase(
            showcaseKey: ShowcaseKeys.homeScanCard,
            group: ShowcaseKeys.homeGroup,
            title: 'Scan a Bill',
            description:
                'Snap or upload a receipt — BillSplit reads the '
                'items for you automatically.',
            icon: Icons.document_scanner_outlined,
            child: ScanBillCard(onTap: onScanTap),
          ),
          const SizedBox(height: 16),
          AppTextField(
            hint: 'Search friends',
            prefixIcon: Icons.search,
            textInputAction: TextInputAction.search,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Friends',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightTextPrimary,
                ),
              ),
              TextButton(
                onPressed: onSeeAllTap,
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
