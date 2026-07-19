import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../split/presentation/providers/bill_flow_state.dart';
import 'edit_field_decoration.dart';

class TaxField extends StatefulWidget {
  const TaxField({super.key});

  @override
  State<TaxField> createState() => _TaxFieldState();
}

class _TaxFieldState extends State<TaxField> {
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
            decoration: editFieldDecoration(hint: '0.00', prefixText: '₹ '),
            onChanged: (value) => context.read<BillFlowState>().setTaxAmount(
              double.tryParse(value) ?? 0,
            ),
          ),
        ),
      ],
    );
  }
}
