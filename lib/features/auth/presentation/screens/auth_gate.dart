import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../home/presentation/screens/home_screen.dart';
import '../../domain/entities/app_user.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final AppUser? user = context.watch<AppUser?>();
    return user == null ? const LoginScreen() : const HomeScreen();
  }
}
