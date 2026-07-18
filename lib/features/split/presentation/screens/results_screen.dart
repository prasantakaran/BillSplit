import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/bill.dart';
import '../../../../core/models/settlement.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/upi_link_builder.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../history/data/repositories/bills_repository.dart';
import '../providers/bill_flow_state.dart';

/// Final step of the bill flow: per-person totals, UPI payment requests,
/// and saving the bill to history.
///
/// Friends owe the signed-in user (who paid the restaurant), so payment
/// links are built with the user's UPI ID as payee and shared to friends.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.settlements});

  final List<Settlement> settlements;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late final BillsRepository _repository;
  late final User _user;

  final TextEditingController _restaurantController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();
  final ValueNotifier<bool> _isSaving = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _user = context.read<User?>()!;
    _repository = BillsRepository(
      firestore: FirebaseFirestore.instance,
      uid: _user.uid,
    );
    _restaurantController.text = context.read<BillFlowState>().restaurantName;
  }

  @override
  void dispose() {
    _restaurantController.dispose();
    _upiController.dispose();
    _isSaving.dispose();
    super.dispose();
  }

  String get _billName {
    final String name = _restaurantController.text.trim();
    return name.isEmpty ? 'Restaurant Bill' : name;
  }

  String? get _myUpiId {
    final String upi = _upiController.text.trim();
    return upi.isEmpty || Validators.upiId(upi) != null ? null : upi;
  }

  String _paymentMessage(Settlement s) {
    final StringBuffer message = StringBuffer()
      ..writeln('Hi ${s.friendName}!')
      ..writeln(
        'Your share of "$_billName" on BillSplit is '
        '${CurrencyFormatter.format(s.totalOwed)} '
        '(items ${CurrencyFormatter.format(s.itemsTotal)} + '
        'tax ${CurrencyFormatter.format(s.taxShare)}).',
      );
    final String? upi = _myUpiId;
    if (upi != null) {
      message
        ..writeln()
        ..writeln('Pay here:')
        ..writeln(
          UpiLinkBuilder.build(
            payeeUpiId: upi,
            payeeName: _user.displayName ?? 'BillSplit user',
            amount: s.totalOwed,
            note: 'BillSplit: $_billName',
          ),
        );
    }
    return message.toString();
  }

  Future<void> _shareRequest(Settlement s) async {
    await SharePlus.instance.share(ShareParams(text: _paymentMessage(s)));
  }

  Future<void> _previewUpiLink(Settlement s) async {
    final String? upi = _myUpiId;
    if (upi == null) {
      _showMessage('Enter your UPI ID above to build payment links.');
      return;
    }
    final Uri link = Uri.parse(
      UpiLinkBuilder.build(
        payeeUpiId: upi,
        payeeName: _user.displayName ?? 'BillSplit user',
        amount: s.totalOwed,
        note: 'BillSplit: $_billName',
      ),
    );
    final bool launched =
        await launchUrl(link, mode: LaunchMode.externalApplication);
    if (!launched) {
      _showMessage('No UPI app found on this device.');
    }
  }

  Future<void> _saveBill() async {
    final BillFlowState flow = context.read<BillFlowState>();
    final Bill bill = Bill(
      id: const Uuid().v4(),
      restaurantName: _billName,
      createdAt: DateTime.now(),
      items: flow.items,
      taxAmount: flow.taxAmount,
      totalAmount: flow.grandTotal,
      settlements: widget.settlements,
    );

    _isSaving.value = true;
    try {
      // Firestore's set() future only completes once the SERVER acknowledges
      // the write. Offline, the write is queued locally and synced later —
      // so a timeout means "queued", not "failed".
      await _repository.saveBill(bill).timeout(const Duration(seconds: 10));
      _finishSave('Bill saved to your history.');
    } on TimeoutException {
      _finishSave(
        'No connection — bill saved on this device and will sync when online.',
      );
    } on FirebaseException catch (e) {
      _showMessage('Could not save the bill: ${e.message ?? e.code}');
    } catch (e) {
      _showMessage('Could not save the bill: $e');
    } finally {
      if (mounted) {
        _isSaving.value = false;
      }
    }
  }

  void _finishSave(String message) {
    if (!mounted) {
      return;
    }
    context.read<BillFlowState>().reset();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final BillFlowState flow = context.watch<BillFlowState>();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(title: const Text('Split Results')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  AppTextField(
                    controller: _restaurantController,
                    hint: 'Restaurant name (optional)',
                    prefixIcon: Icons.storefront_outlined,
                    textInputAction: TextInputAction.next,
                    onChanged: (value) => context
                        .read<BillFlowState>()
                        .setRestaurantName(value),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _upiController,
                    hint: 'Your UPI ID — to receive payments',
                    prefixIcon: Icons.currency_rupee,
                    textInputAction: TextInputAction.done,
                    validator: Validators.upiId,
                  ),
                  const SizedBox(height: 20),
                  for (final Settlement s in widget.settlements)
                    _SettlementCard(
                      settlement: s,
                      onShare: () => _shareRequest(s),
                      onPreviewLink: () => _previewUpiLink(s),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bill total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(flow.grandTotal),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandNavy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: const BoxDecoration(
                color: AppColors.lightSurface,
                border: Border(top: BorderSide(color: AppColors.lightBorder)),
              ),
              child: ValueListenableBuilder<bool>(
                valueListenable: _isSaving,
                builder: (context, isSaving, _) => AppButton(
                  label: 'Save Bill',
                  icon: Icons.check_circle_outline,
                  isLoading: isSaving,
                  onPressed: _saveBill,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({
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
