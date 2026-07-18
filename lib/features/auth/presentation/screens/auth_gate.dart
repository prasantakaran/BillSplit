import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../home/presentation/screens/home_screen.dart';
import 'login_screen.dart';

/// Routes to the right screen based on authentication state.
///
/// Rebuilds whenever the `StreamProvider<User?>` emits, so signing in or out
/// swaps the screen automatically — no manual navigation needed.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<User?>();
    return user == null ? const LoginScreen() : const HomeScreen();
  }
}
