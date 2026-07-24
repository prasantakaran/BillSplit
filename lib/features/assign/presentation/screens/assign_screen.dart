import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/friend.dart';
import '../../../../core/models/settlement.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_showcase_display_service.dart';
import '../../../../core/utils/showcase_keys.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../../shared/widgets/show_case_widget.dart';
import '../../../friends/domain/repositories/friends_repository.dart';
import '../../../friends/presentation/widgets/add_friend_dialog.dart';
import '../../../../shared/providers/bill_flow_state.dart';
import '../../../results/presentation/screens/results_screen.dart';
import '../../domain/services/settlement_calculator.dart';
import '../widgets/assign_footer.dart';
import '../widgets/assign_item_card.dart';
import '../widgets/no_friends_yet.dart';

class AssignScreen extends StatefulWidget {
  const AssignScreen({super.key});

  @override
  State<AssignScreen> createState() => _AssignScreenState();
}

class _AssignScreenState extends State<AssignScreen> {
  late final FriendsRepository _repository;
  late final Stream<List<Friend>> _friendsStream;
  bool _showcaseTriggered = false;

  @override
  void initState() {
    super.initState();
    _repository = context.read<FriendsRepository?>()!;
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
      appBar: const AppTopBar(title: 'Assign Items'),
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

            if (!_showcaseTriggered && flow.items.isNotEmpty) {
              _showcaseTriggered = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AppShowcaseService.startIfUnseen(ShowcaseKeys.assignScreenId);
              });
            }

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
                    itemBuilder: (context, index) {
                      final Widget card = AssignItemCard(
                        item: flow.items[index],
                        friends: friends,
                        onAddFriend: _addFriend,
                      );
                      if (index != 0) {
                        return card;
                      }
                      return AppShowcase(
                        showcaseKey: ShowcaseKeys.assignFirstItemCard,
                        group: ShowcaseKeys.assignGroup,
                        title: 'Assign Items',
                        description:
                            'Tap each friend\'s name to mark who '
                            'shared this item.',
                        icon: Icons.checklist_rtl,
                        child: card,
                      );
                    },
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
