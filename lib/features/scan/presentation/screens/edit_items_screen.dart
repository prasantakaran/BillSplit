import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/bill_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../split/presentation/providers/bill_flow_state.dart';
import '../../../split/presentation/screens/assign_screen.dart';

/// Lets the user fix OCR mistakes before splitting: rename items, correct
/// prices, add or remove rows, and adjust the tax amount.
class EditItemsScreen extends StatelessWidget {
  const EditItemsScreen({super.key});

  void _continueToAssign(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AssignScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BillFlowState flow = context.watch<BillFlowState>();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(title: const Text('Edit Items')),
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
                  for (final BillItem item in flow.items)
                    _ItemRow(key: ValueKey(item.id), item: item),
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
                  _TaxField(key: ValueKey('tax-${flow.items.length}')),
                ],
              ),
            ),
            _TotalsBar(flow: flow, onContinue: () => _continueToAssign(context)),
          ],
        ),
      ),
    );
  }
}

/// One editable item row: name, price, delete.
class _ItemRow extends StatefulWidget {
  const _ItemRow({super.key, required this.item});

  final BillItem item;

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.item.name);
  late final TextEditingController _priceController = TextEditingController(
    text: widget.item.price == 0
        ? ''
        : widget.item.price.toStringAsFixed(
            widget.item.price.truncateToDouble() == widget.item.price ? 0 : 2,
          ),
  );

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.lightTextSecondary),
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
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration('Item name'),
              onChanged: (value) =>
                  flow.updateItem(widget.item.id, name: value.trim()),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              decoration: _decoration('0.00'),
              onChanged: (value) => flow.updateItem(
                widget.item.id,
                price: double.tryParse(value) ?? 0,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove item',
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.lightTextSecondary,
            ),
            onPressed: () => flow.removeItem(widget.item.id),
          ),
        ],
      ),
    );
  }
}

/// Editable tax amount field, seeded from the parsed bill.
class _TaxField extends StatefulWidget {
  const _TaxField({super.key});

  @override
  State<_TaxField> createState() => _TaxFieldState();
}

class _TaxFieldState extends State<_TaxField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final double tax = context.read<BillFlowState>().taxAmount;
    _controller = TextEditingController(
      text: tax == 0 ? '' : tax.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Tax / GST amount',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.lightTextPrimary,
            ),
          ),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: '₹ ',
              isDense: true,
              filled: true,
              fillColor: AppColors.lightSurface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.lightBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.brandBlue, width: 1.5),
              ),
            ),
            onChanged: (value) => context
                .read<BillFlowState>()
                .setTaxAmount(double.tryParse(value) ?? 0),
          ),
        ),
      ],
    );
  }
}

/// Sticky footer: subtotal, tax, grand total and the continue button.
class _TotalsBar extends StatelessWidget {
  const _TotalsBar({required this.flow, required this.onContinue});

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
          AppButton(
            label: 'Continue',
            trailingIcon: Icons.arrow_forward,
            onPressed: flow.hasItems ? onContinue : null,
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
