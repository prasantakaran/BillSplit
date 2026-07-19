import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/bill.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_top_bar.dart';
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
  static final DateFormat _rangeDateFormat = DateFormat('d MMM yyyy');

  late final BillsRepository _repository;
  late final Stream<List<Bill>> _billsStream;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final User user = context.read<User?>()!;
    _repository = BillsRepository(
      firestore: FirebaseFirestore.instance,
      uid: user.uid,
    );
    _billsStream = _repository.watchBills();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Bill> _applyFilters(List<Bill> bills) {
    final String query = _searchQuery.toLowerCase();
    return bills.where((bill) {
      final bool matchesQuery =
          query.isEmpty || bill.restaurantName.toLowerCase().contains(query);
      final bool matchesDate = _selectedDate == null ||
          (bill.createdAt.year == _selectedDate!.year &&
              bill.createdAt.month == _selectedDate!.month &&
              bill.createdAt.day == _selectedDate!.day);
      return matchesQuery && matchesDate;
    }).toList();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: _selectedDate ?? DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _clearDate() {
    setState(() => _selectedDate = null);
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
      appBar: const AppTopBar(title: 'Bill History'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by restaurant name',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _searchController.clear,
                            ),
                      filled: true,
                      fillColor: AppColors.lightSurface,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.lightBorder,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Filter by date',
                  onPressed: _pickDate,
                  icon: Icon(
                    Icons.calendar_month,
                    color: _selectedDate == null
                        ? AppColors.lightTextSecondary
                        : AppColors.brandBlue,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text(_rangeDateFormat.format(_selectedDate!)),
                  avatar: const Icon(Icons.date_range, size: 18),
                  onDeleted: _clearDate,
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Bill>>(
              stream: _billsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load bills.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.lightTextSecondary,
                        ),
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
                final List<Bill> filteredBills = _applyFilters(bills);
                if (filteredBills.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No bills match your search or date filter.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredBills.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final Bill bill = filteredBills[index];
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
          ),
        ],
      ),
    );
  }
}
