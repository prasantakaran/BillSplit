import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/bill.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/bills_repository.dart';
import '../widgets/bill_card.dart';
import '../widgets/bill_detail_sheet.dart';
import '../widgets/empty_history.dart';

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
      builder: (context) =>
          BillDetailSheet(bill: bill, dateFormat: _dateFormat),
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
            return const EmptyHistory();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bills.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final Bill bill = bills[index];
              return BillCard(
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
