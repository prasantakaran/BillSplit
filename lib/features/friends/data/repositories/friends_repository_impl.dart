import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/models/friend.dart';
import '../../../../shared/data/firestore_guard.dart';
import '../../domain/repositories/friends_repository.dart';

class FriendsRepositoryImpl implements FriendsRepository {
  final CollectionReference<Map<String, dynamic>> _collection;

  FriendsRepositoryImpl({
    required FirebaseFirestore firestore,
    required String uid,
  }) : _collection = firestore
           .collection('users')
           .doc(uid)
           .collection('friends');

  @override
  Stream<List<Friend>> watchFriends() {
    return _collection
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Friend.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> addFriend(Friend friend) {
    return guardFirestore(() => _collection.doc(friend.id).set(friend.toMap()));
  }

  @override
  Future<void> updateFriend(Friend friend) {
    return guardFirestore(() => _collection.doc(friend.id).set(friend.toMap()));
  }

  @override
  Future<void> deleteFriend(String id) {
    return guardFirestore(() => _collection.doc(id).delete());
  }
}
