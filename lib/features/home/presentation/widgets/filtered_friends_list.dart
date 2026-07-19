import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/friend.dart';
import '../../../friends/presentation/widgets/friend_card.dart';
import 'dashboard_message.dart';

class FilteredFriendsList extends StatelessWidget {
  const FilteredFriendsList({
    super.key,
    required this.friends,
    required this.searchQuery,
  });

  final List<Friend> friends;
  final ValueListenable<String> searchQuery;

  List<Friend> _filter(String query) {
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: searchQuery,
      builder: (context, query, _) {
        if (friends.isEmpty) {
          return const DashboardMessage(
            icon: Icons.group_outlined,
            title: 'No friends yet',
            subtitle: 'Add the people you split bills with.',
          );
        }
        final List<Friend> filtered = _filter(query);
        if (filtered.isEmpty) {
          return DashboardMessage(
            icon: Icons.search_off,
            title: 'No matches',
            subtitle: 'No friends match "${query.trim()}".',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => FriendCard(friend: filtered[index]),
        );
      },
    );
  }
}
