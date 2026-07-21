import '../../../../core/models/friend.dart';

// Friends CRUD
abstract class FriendsRepository {
  Stream<List<Friend>> watchFriends();

  Future<void> addFriend(Friend friend);

  Future<void> updateFriend(Friend friend);

  Future<void> deleteFriend(String id);
}
