import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/auth_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

List<SingleChildWidget> buildAuthProviders(AuthService authService) {
  // Built once so the repository and the auth stream stay in sync.
  final AuthRepository repository = AuthRepositoryImpl(
    authService: authService,
  );

  return [
    Provider<AuthRepository>.value(value: repository),

    StreamProvider<AppUser?>.value(
      value: repository.authStateChanges(),
      initialData: repository.currentUser,
    ),
  ];
}
