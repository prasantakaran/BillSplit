import 'package:bill_split/core/models/bill.dart';
import 'package:bill_split/features/results/domain/repository/save_bill_repo.dart';
import 'package:bill_split/shared/data/firestore_guard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SaveBillImplRepo implements SaveBillRepository {
  final CollectionReference<Map<String, dynamic>> _collection;

  SaveBillImplRepo({required FirebaseFirestore firestore, required String uid})
    : _collection = firestore.collection('users').doc(uid).collection('bills');

  @override
  Future<void> saveBill(Bill bill) {
    return guardFirestore(() => _collection.doc(bill.id).set(bill.toMap()));
  }
}
