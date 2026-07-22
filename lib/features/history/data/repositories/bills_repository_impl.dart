import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/models/bill.dart';
import '../../domain/repositories/bills_repository.dart';

class BillsRepositoryImpl implements BillsRepository {
  final CollectionReference<Map<String, dynamic>> _collection;

  BillsRepositoryImpl({
    required FirebaseFirestore firestore,
    required String uid,
  }) : _collection = firestore.collection('users').doc(uid).collection('bills');

  @override
  Stream<List<Bill>> watchBills() {
    return _collection
        .orderBy('createdAtMillis', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Bill.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> deleteBill(String id) {
    return _collection.doc(id).delete();
  }
}
