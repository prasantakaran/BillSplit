import 'package:bill_split/core/models/bill.dart';

abstract class SaveBillRepository {
  Future<void> saveBill(Bill bill);
}
