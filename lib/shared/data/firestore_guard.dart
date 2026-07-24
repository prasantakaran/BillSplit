import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/exceptions/data_exception.dart';

Future<T> guardFirestore<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on FirebaseException catch (e) {
    throw DataException(e.message ?? e.code);
  }
}
