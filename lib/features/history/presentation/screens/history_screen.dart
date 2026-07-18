import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/bill.dart';
import '../../../../core/models/bill_item.dart';
import '../../../../core/models/settlement.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/repositories/bills_repository.dart';

/// Past bills, live from Firestore, newest first.
///
/// Plain StreamBuilder on the repository stream, per the architecture.
/// Tapping a bill opens a detail sheet with items and per-person shares.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static final DateFormat _dateFormat = DateFormat('d MMM yyyy, h:mm a');

  late final BillsRepository _repository;
  late final Stream<List<Bill>> _billsStream;

  @override
  void initState() {
    super.initState();
    final User user = context.read<User?>()!;
    _repository = BillsRepository(
      firestore: FirebaseFirestore.instance,
      uid: user.uid,
    );
    _billsStream = _repository.watchBills();
  }

  Future<void> _confirmDelete(Bill bill) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete bill?'),
        content: Text(
          '"${bill.restaurantName}" from '
          '${_dateFormat.format(bill.createdAt)} will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.negativeAmount),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await _repository.deleteBill(bill.id);
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not delete bill: ${e.message ?? e.code}'),
          ),
        );
    }
  }

  void _showBillDetail(Bill bill) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.lightBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _BillDetailSheet(
        bill: bill,
        dateFormat: _dateFormat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(title: const Text('Bill History')),
      body: StreamBuilder<List<Bill>>(
        stream: _billsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load bills.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.lightTextSecondary),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<Bill> bills = snapshot.data!;
          if (bills.isEmpty) {
            return const _EmptyHistory();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bills.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final Bill bill = bills[index];
              return _BillCard(
                bill: bill,
                dateText: _dateFormat.format(bill.createdAt),
                onTap: () => _showBillDetail(bill),
                onDelete: () => _confirmDelete(bill),
              );
            },
          );
        },
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({
    required this.bill,
    required this.dateText,
    required this.onTap,
    required this.onDelete,
  });

  final Bill bill;
  final String dateText;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: AppColors.brandBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.restaurantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      '$dateText - ${bill.settlements.length} '
                      '${bill.settlements.length == 1 ? 'person' : 'people'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(bill.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandNavy,
                ),
              ),
              IconButton(
                tooltip: 'Delete bill',
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.lightTextSecondary,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BillDetailSheet extends StatelessWidget {
  const _BillDetailSheet({required this.bill, required this.dateFormat});

  final Bill bill;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
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
                dateFormat.format(bill.createdAt),
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
              const Text(
                'Who owed what',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              for (final Settlement s in bill.settlements)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.friendName,
                          style: const TextStyle(
                            color: AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(s.totalOwed),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandNavy,
                        ),
                      ),
                    ],
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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.brandBlue.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'No bills yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bills you split will show up here.',
            style: TextStyle(color: AppColors.lightTextSecondary),
          ),
        ],
      ),
    );
  }
}
