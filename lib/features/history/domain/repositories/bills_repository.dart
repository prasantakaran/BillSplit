import '../../../../core/models/bill.dart';

// Saved-bill CRUD
abstract class BillsRepository {
  Stream<List<Bill>> watchBills();

  Future<void> saveBill(Bill bill);

  Future<void> deleteBill(String id);
}
