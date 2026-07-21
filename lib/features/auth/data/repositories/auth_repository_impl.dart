import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;
  AuthRepositoryImpl({required AuthService authService})
    : _authService = authService;

  @override
  AppUser? get currentUser => _toAppUser(_authService.currentUser);

  @override
  Stream<AppUser?> authStateChanges() =>
      _authService.authStateChanges().map(_toAppUser);

  @override
  Future<void> signInWithEmail(String email, String password) =>
      _authService.signInWithEmail(email, password);

  @override
  Future<void> registerWithEmail(String email, String password) =>
      _authService.registerWithEmail(email, password);

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _authService.sendPasswordResetEmail(email);

  @override
  Future<bool> signInWithGoogle() => _authService.signInWithGoogle();

  @override
  Future<void> signOut() => _authService.signOut();

  static AppUser? _toAppUser(firebase.User? user) {
    if (user == null) {
      return null;
    }
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}
