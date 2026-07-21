import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/friend.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_showcase_display_service.dart';
import '../../../../core/utils/showcase_keys.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../../shared/widgets/show_case_widget.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../friends/data/repositories/friends_repository_impl.dart';
import '../../../friends/domain/repositories/friends_repository.dart';
import '../../../friends/presentation/screens/friends_screen.dart';
import '../../../friends/presentation/widgets/add_friend_dialog.dart';
import '../../../history/presentation/screens/history_screen.dart';
import '../../../scan/presentation/screens/scan_screen.dart';
import '../widgets/filtered_friends_list.dart';
import '../widgets/home_header.dart';
import '../widgets/home_nav_bar.dart';
import '../widgets/logout_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final FriendsRepository _repository;
  late final Stream<List<Friend>> _friendsStream;

  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');

  /// 0 = dashboard, 1 = bill history.
  final ValueNotifier<int> _tabIndex = ValueNotifier<int>(0);

  /// Set when [_resumeLostScan] navigates away to a recovered scan, so the
  /// dashboard showcase doesn't start underneath the pushed screen.
  bool _navigatedAway = false;

  @override
  void initState() {
    super.initState();
    final User user = context.read<User?>()!;
    _repository = FriendsRepositoryImpl(
      firestore: FirebaseFirestore.instance,
      uid: user.uid,
    );
    _friendsStream = _repository.watchFriends();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _resumeLostScan();
      if (mounted && !_navigatedAway) {
        AppShowcaseService.startIfUnseen(ShowcaseKeys.homeScreenId);
      }
    });
  }

  @override
  void dispose() {
    _searchQuery.dispose();
    _tabIndex.dispose();
    super.dispose();
  }

  Future<void> _resumeLostScan() async {
    try {
      final LostDataResponse response = await ImagePicker().retrieveLostData();
      if (!mounted || response.isEmpty) {
        return;
      }
      final List<XFile>? files = response.files;
      if (files == null || files.isEmpty) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Recovered your bill photo — continuing the scan.'),
          ),
        );
      _navigatedAway = true;
      _push(ScanScreen(initialImagePath: files.first.path));
    } on Exception {
      // Nothing to resume; stay on the dashboard.
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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not add friend: ${e.message ?? e.code}'),
          ),
        );
    }
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  Future<void> _confirmLogout() async {
    final bool confirmed = await LogoutDialog.show(context);
    if (!confirmed || !mounted) {
      return;
    }
    await context.read<AuthRepository>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<User?>();

    return ValueListenableBuilder<int>(
      valueListenable: _tabIndex,
      builder: (context, tabIndex, _) => Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: IndexedStack(
          index: tabIndex,
          children: [_buildDashboard(user), const HistoryScreen()],
        ),
        bottomNavigationBar: HomeNavBar(
          currentIndex: tabIndex,
          onTap: (index) => _tabIndex.value = index,
        ),
      ),
    );
  }

  /// The Home tab: greeting, scan card, searchable friends list.
  Widget _buildDashboard(User? user) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppTopBar(
        title: 'BillSplit',
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      floatingActionButton: AppShowcase(
        showcaseKey: ShowcaseKeys.homeAddFriendFab,
        group: ShowcaseKeys.homeGroup,
        title: 'Add Friends',
        description:
            'Add the people you split bills with — you\'ll pick '
            'from this list when assigning items.',
        icon: Icons.person_add_alt_1,
        child: FloatingActionButton.extended(
          onPressed: _addFriend,
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add Friend'),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeHeader(
              welcomeName: user?.displayName ?? user?.email ?? 'there',
              onScanTap: () => _push(const ScanScreen()),
              onSearchChanged: (value) => _searchQuery.value = value,
              onSeeAllTap: () => _push(const FriendsScreen()),
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
                  return FilteredFriendsList(
                    friends: snapshot.data!,
                    searchQuery: _searchQuery,
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
