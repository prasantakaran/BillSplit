import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/bill.dart';
import '../../../../core/models/settlement.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_showcase_display_service.dart';
import '../../../../core/utils/showcase_keys.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../../shared/widgets/show_case_widget.dart';
import '../../../history/data/repositories/bills_repository.dart';
import '../providers/bill_flow_state.dart';
import '../widgets/bill_total_row.dart';
import '../widgets/save_bill_bar.dart';
import '../widgets/settlement_card.dart';
import '../widgets/settlement_payment_actions.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppShowcaseService.startIfUnseen(ShowcaseKeys.resultsScreenId);
    });
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

  String get _payeeName => _user.displayName ?? 'BillSplit user';

  Future<void> _shareRequest(Settlement s) {
    return SettlementPaymentActions.shareRequest(
      settlement: s,
      billName: _billName,
      payeeName: _payeeName,
      payeeUpiId: _myUpiId,
    );
  }

  Future<void> _previewUpiLink(Settlement s) {
    return SettlementPaymentActions.openUpiApp(
      context,
      settlement: s,
      billName: _billName,
      payeeName: _payeeName,
      payeeUpiId: _myUpiId,
    );
  }

  void _showQrCode(Settlement s) {
    SettlementPaymentActions.showQr(
      context,
      settlement: s,
      billName: _billName,
      payeeName: _payeeName,
      payeeUpiId: _myUpiId,
    );
  }

  Widget _buildSettlementCard(int index) {
    final Settlement s = widget.settlements[index];
    final Widget card = SettlementCard(
      settlement: s,
      onShare: () => _shareRequest(s),
      onPreviewLink: () => _previewUpiLink(s),
      onShowQr: () => _showQrCode(s),
    );
    if (index != 0) {
      return card;
    }
    return AppShowcase(
      showcaseKey: ShowcaseKeys.resultsShareButton,
      group: ShowcaseKeys.resultsGroup,
      title: 'Collect Payment',
      description: 'Share a payment request, open it in a UPI app, or show '
          'a QR code.',
      icon: Icons.share_outlined,
      child: card,
    );
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
      appBar: const AppTopBar(title: 'Split Results'),
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
                    onChanged: (value) =>
                        context.read<BillFlowState>().setRestaurantName(value),
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
                  for (int i = 0; i < widget.settlements.length; i++)
                    _buildSettlementCard(i),
                  const SizedBox(height: 6),
                  BillTotalRow(total: flow.grandTotal),
                ],
              ),
            ),
            SaveBillBar(isSaving: _isSaving, onSave: _saveBill),
          ],
        ),
      ),
    );
  }
}
