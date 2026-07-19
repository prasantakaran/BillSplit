import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/friend.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../friends/data/repositories/friends_repository.dart';
import '../../../friends/presentation/screens/friends_screen.dart';
import '../../../friends/presentation/widgets/add_friend_dialog.dart';
import '../../../history/presentation/screens/history_screen.dart';
import '../../../scan/presentation/screens/scan_screen.dart';
import '../widgets/filtered_friends_list.dart';
import '../widgets/home_header.dart';
import '../widgets/home_nav_bar.dart';

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
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    final User user = context.read<User?>()!;
    _repository = FriendsRepository(
      firestore: FirebaseFirestore.instance,
      uid: user.uid,
    );
    _friendsStream = _repository.watchFriends();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resumeLostScan());
  }

  @override
  void dispose() {
    _searchQuery.dispose();
    super.dispose();
  }

  /// Android may kill the app while the system camera is open; the app then
  /// restarts from scratch and lands here. If image_picker is holding the
  /// photo taken before the kill, jump straight back into the scan flow.
  Future<void> _resumeLostScan() async {
    try {
      final LostDataResponse response =
          await ImagePicker().retrieveLostData();
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

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<User?>();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _buildDashboard(user),
          const HistoryScreen(),
        ],
      ),
      bottomNavigationBar: HomeNavBar(
        currentIndex: _tabIndex,
        onTap: (index) => setState(() => _tabIndex = index),
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
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFriend,
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Friend'),
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
