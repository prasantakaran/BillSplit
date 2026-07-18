import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/friend.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/friends_repository.dart';
import '../widgets/add_friend_dialog.dart';

/// Lists the user's friends live from Firestore.
///
/// Per the app architecture this uses a plain [StreamBuilder] on the
/// repository stream — no provider state is needed for Firestore-backed
/// lists.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  late final FriendsRepository _repository;
  late final Stream<List<Friend>> _friendsStream;

  @override
  void initState() {
    super.initState();
    final User user = context.read<User?>()!;
    _repository = FriendsRepository(
      firestore: FirebaseFirestore.instance,
      uid: user.uid,
    );
    _friendsStream = _repository.watchFriends();
  }

  Future<void> _addFriend() async {
    final Friend? friend = await AddFriendDialog.show(context);
    if (friend == null) {
      return;
    }
    try {
      await _repository.addFriend(friend);
    } on FirebaseException catch (e) {
      _showError('Could not add friend: ${e.message ?? e.code}');
    }
  }

  Future<void> _confirmDelete(Friend friend) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove friend?'),
        content: Text('${friend.name} will be removed from your friends.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Remove',
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
      await _repository.deleteFriend(friend.id);
    } on FirebaseException catch (e) {
      _showError('Could not remove friend: ${e.message ?? e.code}');
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(title: const Text('Friends')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFriend,
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Friend'),
      ),
      body: StreamBuilder<List<Friend>>(
        stream: _friendsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load friends.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.lightTextSecondary),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<Friend> friends = snapshot.data!;
          if (friends.isEmpty) {
            return const _EmptyFriends();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: friends.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final Friend friend = friends[index];
              return _FriendCard(
                friend: friend,
                onDelete: () => _confirmDelete(friend),
              );
            },
          );
        },
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.friend, required this.onDelete});

  final Friend friend;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final String initial =
        friend.name.isEmpty ? '?' : friend.name[0].toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppColors.brandBlue.withValues(alpha: 0.12),
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          friend.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.lightTextPrimary,
          ),
        ),
        subtitle: friend.upiId == null && friend.phone == null
            ? null
            : Text(
                friend.upiId ?? friend.phone!,
                style: const TextStyle(color: AppColors.lightTextSecondary),
              ),
        trailing: IconButton(
          tooltip: 'Remove friend',
          icon: const Icon(
            Icons.delete_outline,
            color: AppColors.lightTextSecondary,
          ),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _EmptyFriends extends StatelessWidget {
  const _EmptyFriends();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.group_outlined,
            size: 64,
            color: AppColors.brandBlue.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'No friends yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add the people you split bills with.',
            style: TextStyle(color: AppColors.lightTextSecondary),
          ),
        ],
      ),
    );
  }
}
