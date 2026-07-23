import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/flavor/app_flavor.dart';
import 'core/utils/app_showcase_display_service.dart';
import 'firebase_options.dart';

/// Shared startup path for every flavor entrypoint.
Future<void> bootstrap(AppFlavor flavor) async {
  AppFlavorConfig.set(flavor);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppShowcaseService.registerShowcaseView();
  runApp(const BillSplitApp());
}
