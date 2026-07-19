import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/friend.dart';
import '../../../../core/models/settlement.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../friends/data/repositories/friends_repository.dart';
import '../../../friends/presentation/widgets/add_friend_dialog.dart';
import '../../domain/settlement_calculator.dart';
import '../providers/bill_flow_state.dart';
import '../widgets/assign_footer.dart';
import '../widgets/assign_item_card.dart';
import '../widgets/no_friends_yet.dart';
import 'results_screen.dart';

class AssignScreen extends StatefulWidget {
  const AssignScreen({super.key});

  @override
  State<AssignScreen> createState() => _AssignScreenState();
}

class _AssignScreenState extends State<AssignScreen> {
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
    if (friend != null) {
      await _repository.addFriend(friend);
    }
  }

  void _openResults(List<Friend> friends) {
    final BillFlowState flow = context.read<BillFlowState>();
    final List<Settlement> settlements = SettlementCalculator.calculate(
      items: flow.items,
      taxAmount: flow.taxAmount,
      friendNamesById: {for (final Friend f in friends) f.id: f.name},
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(settlements: settlements),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BillFlowState flow = context.watch<BillFlowState>();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(title: const Text('Assign Items')),
      body: SafeArea(
        child: StreamBuilder<List<Friend>>(
          stream: _friendsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Could not load friends.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.lightTextSecondary),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<Friend> friends = snapshot.data!;
            if (friends.isEmpty) {
              return NoFriendsYet(onAddFriend: _addFriend);
            }

            final int assignedCount = flow.items
                .where((item) => item.isAssigned)
                .length;

            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
                  child: Text(
                    'Select everyone who shared each item.',
                    style: TextStyle(color: AppColors.lightTextSecondary),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                    itemCount: flow.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => AssignItemCard(
                      item: flow.items[index],
                      friends: friends,
                      onAddFriend: _addFriend,
                    ),
                  ),
                ),
                AssignFooter(
                  assignedCount: assignedCount,
                  totalCount: flow.items.length,
                  onCalculate: flow.allItemsAssigned
                      ? () => _openResults(friends)
                      : null,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
