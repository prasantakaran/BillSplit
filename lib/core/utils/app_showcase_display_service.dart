import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import 'showcase_keys.dart';

class AppShowcaseService {
  AppShowcaseService._();

  static const _prefix = 'showcase_seen_';
  static void registerShowcaseView() {
    ShowcaseView.register(
      skipIfTargetNotPresent: true,
      onComplete: (index, key) {
        for (final entry in ShowcaseKeys.allGroups.entries) {
          if (entry.value.isNotEmpty && entry.value.last == key) {
            markSeen(entry.key);
          }
        }
      },
      onDismiss: (dismissedAt) {
        if (dismissedAt == null) {
          return;
        }
        for (final entry in ShowcaseKeys.allGroups.entries) {
          if (entry.value.contains(dismissedAt)) {
            markSeen(entry.key);
          }
        }
      },
    );
  }

  static Future<bool> hasSeen(String screenId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$screenId') ?? false;
  }

  static Future<void> markSeen(String screenId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$screenId', true);
  }

  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final screenId in ShowcaseKeys.allGroups.keys) {
      await prefs.remove('$_prefix$screenId');
    }
  }

  static Future<void> startIfUnseen(String screenId) async {
    if (await hasSeen(screenId)) {
      return;
    }
    final List<GlobalKey>? keys = ShowcaseKeys.allGroups[screenId];
    if (keys == null || keys.isEmpty) {
      return;
    }
    ShowcaseView.get().startShowCase(keys);
  }
}
