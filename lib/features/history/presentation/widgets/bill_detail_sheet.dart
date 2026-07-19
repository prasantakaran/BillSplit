import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/bill.dart';
import '../../../../core/models/bill_item.dart';
import '../../../../core/models/settlement.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../split/presentation/widgets/settlement_card.dart';
import '../../../split/presentation/widgets/settlement_payment_actions.dart';

/// Bottom-sheet detail view of a saved bill: items, tax/total and
/// per-person shares, with the same share / UPI / QR payment-request
/// actions as the results screen.
class BillDetailSheet extends StatefulWidget {
  const BillDetailSheet({
    super.key,
    required this.bill,
    required this.dateFormat,
  });

  final Bill bill;
  final DateFormat dateFormat;

  @override
  State<BillDetailSheet> createState() => _BillDetailSheetState();
}

class _BillDetailSheetState extends State<BillDetailSheet> {
  final TextEditingController _upiController = TextEditingController();

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  String? get _myUpiId {
    final String upi = _upiController.text.trim();
    return upi.isEmpty || Validators.upiId(upi) != null ? null : upi;
  }

  String get _payeeName =>
      context.read<User?>()?.displayName ?? 'BillSplit user';

  @override
  Widget build(BuildContext context) {
    final Bill bill = widget.bill;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                bill.restaurantName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.dateFormat.format(bill.createdAt),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              for (final BillItem item in bill.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            color: AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(item.price),
                        style: const TextStyle(
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(color: AppColors.lightBorder, height: 20),
              _line('Tax', CurrencyFormatter.format(bill.taxAmount)),
              const SizedBox(height: 4),
              _line(
                'Total',
                CurrencyFormatter.format(bill.totalAmount),
                emphasized: true,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _upiController,
                hint: 'Your UPI ID — to request payments',
                prefixIcon: Icons.currency_rupee,
                textInputAction: TextInputAction.done,
                validator: Validators.upiId,
              ),
              const SizedBox(height: 16),
              const Text(
                'Who owed what',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              for (final Settlement s in bill.settlements)
                SettlementCard(
                  settlement: s,
                  onShare: () => SettlementPaymentActions.shareRequest(
                    settlement: s,
                    billName: bill.restaurantName,
                    payeeName: _payeeName,
                    payeeUpiId: _myUpiId,
                  ),
                  onPreviewLink: () => SettlementPaymentActions.openUpiApp(
                    context,
                    settlement: s,
                    billName: bill.restaurantName,
                    payeeName: _payeeName,
                    payeeUpiId: _myUpiId,
                  ),
                  onShowQr: () => SettlementPaymentActions.showQr(
                    context,
                    settlement: s,
                    billName: bill.restaurantName,
                    payeeName: _payeeName,
                    payeeUpiId: _myUpiId,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(String label, String value, {bool emphasized = false}) {
    final TextStyle style = TextStyle(
      fontSize: emphasized ? 16 : 13.5,
      fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
      color: emphasized ? AppColors.brandNavy : AppColors.lightTextSecondary,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}
