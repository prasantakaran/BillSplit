import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/showcase_keys.dart';
import '../../../../shared/widgets/show_case_widget.dart';

class HomeNavBar extends StatelessWidget {
  const HomeNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: AppColors.brandNavy,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white60,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: AppShowcase(
            showcaseKey: ShowcaseKeys.navHome,
            group: ShowcaseKeys.homeGroup,
            title: 'Dashboard',
            description:
                'Your home base — scan bills and manage friends '
                'from here.',
            icon: Icons.home_outlined,
            child: const Icon(Icons.home_outlined),
          ),
          activeIcon: AppShowcase(
            showcaseKey: ShowcaseKeys.navHome,
            group: ShowcaseKeys.homeGroup,
            title: 'Dashboard',
            description:
                'Your home base — scan bills and manage friends '
                'from here.',
            icon: Icons.home,
            child: const Icon(Icons.home),
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: AppShowcase(
            showcaseKey: ShowcaseKeys.navHistory,
            group: ShowcaseKeys.homeGroup,
            title: 'Bill History',
            description:
                'Every bill you\'ve split before, all in one '
                'place.',
            icon: Icons.history_outlined,
            child: const Icon(Icons.history_outlined),
          ),
          activeIcon: AppShowcase(
            showcaseKey: ShowcaseKeys.navHistory,
            group: ShowcaseKeys.homeGroup,
            title: 'Bill History',
            description:
                'Every bill you\'ve split before, all in one '
                'place.',
            icon: Icons.history,
            child: const Icon(Icons.history),
          ),
          label: 'History',
        ),
      ],
    );
  }
}
