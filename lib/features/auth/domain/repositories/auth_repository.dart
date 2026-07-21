import '../entities/app_user.dart';

abstract class AuthRepository {
  AppUser? get currentUser;

  Stream<AppUser?> authStateChanges();

  Future<void> signInWithEmail(String email, String password);

  Future<void> registerWithEmail(String email, String password);

  Future<void> sendPasswordResetEmail(String email);

  /// Runs the Google account picker. Returns false if the user cancels it.
  Future<bool> signInWithGoogle();

  Future<void> signOut();
}
