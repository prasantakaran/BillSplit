import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/models/bill.dart';

/// Firestore access for the signed-in user's saved bills.
///
/// Per the app architecture, repositories are the only classes allowed to
/// talk to Firestore.
class BillsRepository {
  BillsRepository({required FirebaseFirestore firestore, required String uid})
      : _collection = firestore.collection('users').doc(uid).collection('bills');

  final CollectionReference<Map<String, dynamic>> _collection;

  /// Live list of saved bills, newest first.
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

  Future<void> saveBill(Bill bill) {
    return _collection.doc(bill.id).set(bill.toMap());
  }

  Future<void> deleteBill(String id) {
    return _collection.doc(id).delete();
  }
}
