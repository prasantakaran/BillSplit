import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Brand app bar used across all screens: navy background, white
/// title/icons.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      backgroundColor: AppColors.brandNavy,
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }
}
