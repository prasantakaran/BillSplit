import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/bill_item.dart';
import '../../../../core/models/friend.dart';
import '../../../../core/models/settlement.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../friends/data/repositories/friends_repository.dart';
import '../../../friends/presentation/widgets/add_friend_dialog.dart';
import '../../domain/settlement_calculator.dart';
import '../providers/bill_flow_state.dart';
import 'results_screen.dart';

/// Assigns each bill item to the friends who shared it.
///
/// Friends stream live from Firestore (plain StreamBuilder, per the
/// architecture); assignments are stored on the draft bill in
/// [BillFlowState]. Continue runs [SettlementCalculator] and previews the
/// per-person split.
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
              return _NoFriendsYet(onAddFriend: _addFriend);
            }

            final int assignedCount =
                flow.items.where((item) => item.isAssigned).length;

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
                    itemBuilder: (context, index) => _AssignItemCard(
                      item: flow.items[index],
                      friends: friends,
                      onAddFriend: _addFriend,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  decoration: const BoxDecoration(
                    color: AppColors.lightSurface,
                    border:
                        Border(top: BorderSide(color: AppColors.lightBorder)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$assignedCount of ${flow.items.length} items assigned',
                        style: const TextStyle(
                          color: AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Calculate Split',
                        trailingIcon: Icons.arrow_forward,
                        onPressed: flow.allItemsAssigned
                            ? () => _openResults(friends)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// One bill item with a chip per friend.
class _AssignItemCard extends StatelessWidget {
  const _AssignItemCard({
    required this.item,
    required this.friends,
    required this.onAddFriend,
  });

  final BillItem item;
  final List<Friend> friends;
  final VoidCallback onAddFriend;

  @override
  Widget build(BuildContext context) {
    final BillFlowState flow = context.read<BillFlowState>();
    final int sharerCount = item.sharedByFriendIds.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isAssigned ? AppColors.brandTeal : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name.isEmpty ? '(unnamed item)' : item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
              ),
              Text(
                CurrencyFormatter.format(item.price),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandNavy,
                ),
              ),
            ],
          ),
          if (sharerCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                sharerCount == 1
                    ? 'Paid by 1 person'
                    : 'Split $sharerCount ways - '
                        '${CurrencyFormatter.format(item.price / sharerCount)} each',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.brandTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final Friend friend in friends)
                FilterChip(
                  label: Text(friend.name),
                  selected: item.sharedByFriendIds.contains(friend.id),
                  onSelected: (_) =>
                      flow.toggleAssignment(item.id, friend.id),
                  selectedColor: AppColors.brandBlue.withValues(alpha: 0.14),
                  checkmarkColor: AppColors.brandBlue,
                  labelStyle: TextStyle(
                    color: item.sharedByFriendIds.contains(friend.id)
                        ? AppColors.brandBlue
                        : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  side: const BorderSide(color: AppColors.lightBorder),
                  backgroundColor: AppColors.lightSurface,
                ),
              ActionChip(
                avatar: const Icon(
                  Icons.person_add_alt_1,
                  size: 18,
                  color: AppColors.brandBlue,
                ),
                label: const Text('Add friend'),
                labelStyle: const TextStyle(
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w600,
                ),
                side: const BorderSide(color: AppColors.lightBorder),
                backgroundColor: AppColors.lightSurface,
                onPressed: onAddFriend,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoFriendsYet extends StatelessWidget {
  const _NoFriendsYet({required this.onAddFriend});

  final VoidCallback onAddFriend;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_add_outlined,
              size: 64,
              color: AppColors.brandBlue.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add friends first',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You need at least one friend to split this bill with.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Add Friend',
              icon: Icons.person_add_alt_1,
              onPressed: onAddFriend,
            ),
          ],
        ),
      ),
    );
  }
}
