import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/tax_line.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/bill_flow_state.dart';
import 'edit_field_decoration.dart';

/// Editable list of the bill's tax/charge lines (CGST, SGST, service
/// charge, ...). Lines detected by the scanner seed the list; each can be
/// renamed, re-priced or removed, and new ones added. The bill's total tax
/// is always the sum of these lines.
class TaxLinesEditor extends StatelessWidget {
  const TaxLinesEditor({super.key, required this.taxLines});

  final List<TaxLine> taxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Taxes / Charges',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < taxLines.length; i++)
          TaxLineRow(
            // Count in the key forces fresh controllers after add/remove,
            // when indexes shift.
            key: ValueKey('tax-$i-of-${taxLines.length}'),
            index: i,
            line: taxLines[i],
          ),
        OutlinedButton.icon(
          onPressed: () => context.read<BillFlowState>().addTaxLine(),
          icon: const Icon(Icons.add),
          label: const Text('Add tax / charge'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

/// One editable tax line: name, amount, delete.
class TaxLineRow extends StatefulWidget {
  const TaxLineRow({super.key, required this.index, required this.line});

  final int index;
  final TaxLine line;

  @override
  State<TaxLineRow> createState() => _TaxLineRowState();
}

class _TaxLineRowState extends State<TaxLineRow> {
  late final TextEditingController _labelController = TextEditingController(
    text: widget.line.label,
  );
  late final TextEditingController _amountController = TextEditingController(
    text: widget.line.amount == 0
        ? ''
        : widget.line.amount.toStringAsFixed(
            widget.line.amount.truncateToDouble() == widget.line.amount
                ? 0
                : 2,
          ),
  );

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BillFlowState flow = context.read<BillFlowState>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: TextField(
              controller: _labelController,
              textCapitalization: TextCapitalization.characters,
              decoration: editFieldDecoration(hint: 'Tax name (e.g. CGST)'),
              onChanged: (value) =>
                  flow.updateTaxLine(widget.index, label: value.trim()),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              decoration: editFieldDecoration(hint: '0.00'),
              onChanged: (value) => flow.updateTaxLine(
                widget.index,
                amount: double.tryParse(value) ?? 0,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove tax',
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.lightTextSecondary,
            ),
            onPressed: () => flow.removeTaxLine(widget.index),
          ),
        ],
      ),
    );
  }
}
