import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/friend.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../data/repositories/friends_repository_impl.dart';
import '../../domain/repositories/friends_repository.dart';
import '../widgets/add_friend_dialog.dart';
import '../widgets/friend_card.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  late final FriendsRepository _repository;
  late final Stream<List<Friend>> _friendsStream;

  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    final User user = context.read<User?>()!;
    _repository = FriendsRepositoryImpl(
      firestore: FirebaseFirestore.instance,
      uid: user.uid,
    );
    _friendsStream = _repository.watchFriends();
  }

  @override
  void dispose() {
    _searchQuery.dispose();
    super.dispose();
  }

  List<Friend> _filter(List<Friend> friends, String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return friends;
    }
    return friends.where((friend) {
      return friend.name.toLowerCase().contains(q) ||
          (friend.upiId?.toLowerCase().contains(q) ?? false) ||
          (friend.phone?.contains(q) ?? false);
    }).toList();
  }

  Future<void> _editFriend(Friend friend) async {
    final Friend? edited = await AddFriendDialog.show(context, initial: friend);
    if (edited == null) {
      return;
    }
    try {
      await _repository.updateFriend(edited);
    } on FirebaseException catch (e) {
      _showError('Could not update friend: ${e.message ?? e.code}');
    }
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
    AppSnackbar.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: const AppTopBar(title: 'Friends'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFriend,
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Friend'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: AppTextField(
                hint: 'Search friends',
                prefixIcon: Icons.search,
                textInputAction: TextInputAction.search,
                onChanged: (value) => _searchQuery.value = value,
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Friend>>(
                stream: _friendsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not load friends.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final List<Friend> friends = snapshot.data!;
                  return ValueListenableBuilder<String>(
                    valueListenable: _searchQuery,
                    builder: (context, query, _) {
                      if (friends.isEmpty) {
                        return const _FriendsMessage(
                          icon: Icons.group_outlined,
                          title: 'No friends yet',
                          subtitle: 'Add the people you split bills with.',
                        );
                      }
                      final List<Friend> filtered = _filter(friends, query);
                      if (filtered.isEmpty) {
                        return _FriendsMessage(
                          icon: Icons.search_off,
                          title: 'No matches',
                          subtitle: 'No friends match "${query.trim()}".',
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final Friend friend = filtered[index];
                          return FriendCard(
                            friend: friend,
                            onEdit: () => _editFriend(friend),
                            onDelete: () => _confirmDelete(friend),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendsMessage extends StatelessWidget {
  const _FriendsMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.brandBlue.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.lightTextSecondary),
          ),
        ],
      ),
    );
  }
}
