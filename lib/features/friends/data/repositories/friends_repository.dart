import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/models/friend.dart';

/// Firestore access for the signed-in user's friends.
///
/// Per the app architecture, repositories are the only classes allowed to
/// talk to Firestore — screens consume this via [watchFriends] streams.
class FriendsRepository {
  FriendsRepository({required FirebaseFirestore firestore, required String uid})
      : _collection =
            firestore.collection('users').doc(uid).collection('friends');

  final CollectionReference<Map<String, dynamic>> _collection;

  /// Live list of friends, ordered by name.
  Stream<List<Friend>> watchFriends() {
    return _collection.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Friend.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> addFriend(Friend friend) {
    return _collection.doc(friend.id).set(friend.toMap());
  }

  /// Overwrites the friend document with the edited details.
  Future<void> updateFriend(Friend friend) {
    return _collection.doc(friend.id).set(friend.toMap());
  }

  Future<void> deleteFriend(String id) {
    return _collection.doc(id).delete();
  }
}
