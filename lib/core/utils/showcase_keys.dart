import 'package:flutter/widgets.dart';

class ShowcaseKeys {
  ShowcaseKeys._();

  // ── Home
  static const String homeScreenId = 'home';
  static final GlobalKey homeScanCard = GlobalKey(debugLabel: 'homeScanCard');
  static final GlobalKey homeAddFriendFab = GlobalKey(
    debugLabel: 'homeAddFriendFab',
  );
  static final GlobalKey navHome = GlobalKey(debugLabel: 'navHome');
  static final GlobalKey navHistory = GlobalKey(debugLabel: 'navHistory');
  static List<GlobalKey> get homeGroup => [
    homeScanCard,
    homeAddFriendFab,
    navHome,
    navHistory,
  ];

  // ── Scan
  static const String scanScreenId = 'scan';
  static final GlobalKey scanSourceButtons = GlobalKey(
    debugLabel: 'scanSourceButtons',
  );
  static final GlobalKey scanDetectButton = GlobalKey(
    debugLabel: 'scanDetectButton',
  );

  static final GlobalKey scanManualButton = GlobalKey(
    debugLabel: 'scanManualButton',
  );
  static List<GlobalKey> get scanGroup => [
    scanSourceButtons,
    scanDetectButton,
    scanManualButton,
  ];

  // ── Edit items
  static const String editItemsScreenId = 'editItems';
  static final GlobalKey editAddItemButton = GlobalKey(
    debugLabel: 'editAddItemButton',
  );
  static final GlobalKey editContinueButton = GlobalKey(
    debugLabel: 'editContinueButton',
  );
  static List<GlobalKey> get editItemsGroup => [
    editAddItemButton,
    editContinueButton,
  ];

  // ── Assign
  static const String assignScreenId = 'assign';
  static final GlobalKey assignFirstItemCard = GlobalKey(
    debugLabel: 'assignFirstItemCard',
  );
  static final GlobalKey assignCalculateButton = GlobalKey(
    debugLabel: 'assignCalculateButton',
  );
  static List<GlobalKey> get assignGroup => [
    assignFirstItemCard,
    assignCalculateButton,
  ];

  // ── Results
  static const String resultsScreenId = 'results';
  static final GlobalKey resultsShareButton = GlobalKey(
    debugLabel: 'resultsShareButton',
  );
  static final GlobalKey resultsSaveButton = GlobalKey(
    debugLabel: 'resultsSaveButton',
  );
  static List<GlobalKey> get resultsGroup => [
    resultsShareButton,
    resultsSaveButton,
  ];

  static Map<String, List<GlobalKey>> get allGroups => {
    homeScreenId: homeGroup,
    scanScreenId: scanGroup,
    editItemsScreenId: editItemsGroup,
    assignScreenId: assignGroup,
    resultsScreenId: resultsGroup,
  };

  static int stepIndexOf(GlobalKey key, List<GlobalKey> group) {
    final idx = group.indexOf(key);
    return idx == -1 ? 1 : idx + 1;
  }
}
