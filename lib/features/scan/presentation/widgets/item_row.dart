import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/bill_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../split/presentation/providers/bill_flow_state.dart';
import 'edit_field_decoration.dart';

class ItemRow extends StatefulWidget {
  const ItemRow({super.key, required this.item});

  final BillItem item;

  @override
  State<ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<ItemRow> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.item.name,
  );
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
              decoration: editFieldDecoration(hint: 'Item name'),
              onChanged: (value) =>
                  flow.updateItem(widget.item.id, name: value.trim()),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              decoration: editFieldDecoration(hint: '0.00'),
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
