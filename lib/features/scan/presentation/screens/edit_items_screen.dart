import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/bill_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../split/presentation/providers/bill_flow_state.dart';
import '../../../split/presentation/screens/assign_screen.dart';
import '../widgets/item_row.dart';
import '../widgets/tax_lines_editor.dart';
import '../widgets/totals_bar.dart';

class EditItemsScreen extends StatelessWidget {
  const EditItemsScreen({super.key});

  void _continueToAssign(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AssignScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final BillFlowState flow = context.watch<BillFlowState>();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: const AppTopBar(title: 'Edit Items'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  if (flow.detectedTotal != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Printed total on bill: '
                        '${CurrencyFormatter.format(flow.detectedTotal!)}',
                        style: const TextStyle(
                          color: AppColors.lightTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (flow.subtotalMismatch)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        "Items don't add up to the printed Sub-Total "
                        '(${CurrencyFormatter.format(flow.detectedSubtotal!)})'
                        ' — please check the prices.',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  for (final BillItem item in flow.items)
                    ItemRow(key: ValueKey(item.id), item: item),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: () => context.read<BillFlowState>().addItem(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add item'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TaxLinesEditor(taxLines: flow.taxLines),
                ],
              ),
            ),
            TotalsBar(flow: flow, onContinue: () => _continueToAssign(context)),
          ],
        ),
      ),
    );
  }
}
