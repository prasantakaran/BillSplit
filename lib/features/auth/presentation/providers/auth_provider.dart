import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/auth_service.dart';
import '../../domain/repositories/auth_repository.dart';

List<SingleChildWidget> buildAuthProviders(AuthService authService) {
  return [
    Provider<AuthRepository>.value(
      value: AuthRepositoryImpl(authService: authService),
    ),

    StreamProvider<User?>.value(
      value: authService.authStateChanges(),
      initialData: authService.currentUser,
    ),
  ];
}
