import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/showcase_keys.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/show_case_widget.dart';
import '../../../../shared/providers/bill_flow_state.dart';

class TotalsBar extends StatelessWidget {
  const TotalsBar({super.key, required this.flow, required this.onContinue});

  final BillFlowState flow;
  final VoidCallback onContinue;

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
          _totalLine('Subtotal', flow.subtotal),
          const SizedBox(height: 4),
          _totalLine('Tax', flow.taxAmount),
          const SizedBox(height: 6),
          _totalLine('Total', flow.grandTotal, emphasized: true),
          const SizedBox(height: 14),
          AppShowcase(
            showcaseKey: ShowcaseKeys.editContinueButton,
            group: ShowcaseKeys.editItemsGroup,
            title: 'Continue',
            description:
                'Happy with the items and totals? Continue to '
                'assign them to your friends.',
            icon: Icons.arrow_forward,
            child: AppButton(
              label: 'Continue',
              trailingIcon: Icons.arrow_forward,
              onPressed: flow.hasItems ? onContinue : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalLine(String label, double amount, {bool emphasized = false}) {
    final TextStyle style = TextStyle(
      fontSize: emphasized ? 17 : 14,
      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
      color: emphasized ? AppColors.brandNavy : AppColors.lightTextSecondary,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(CurrencyFormatter.format(amount), style: style),
      ],
    );
  }
}
