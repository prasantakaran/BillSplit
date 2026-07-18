import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../data/services/auth_service.dart';

/// Providers exposing authentication state to the widget tree.
///
/// Per the app architecture, auth state is a plain `StreamProvider<User?>` —
/// no ChangeNotifier is needed for it.
List<SingleChildWidget> buildAuthProviders(AuthService authService) {
  return [
    Provider<AuthService>.value(value: authService),
    StreamProvider<User?>.value(
      value: authService.authStateChanges(),
      initialData: authService.currentUser,
    ),
  ];
}
