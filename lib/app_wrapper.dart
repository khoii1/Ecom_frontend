import 'package:flutter/material.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/screens/auth/login_screen.dart';
import 'package:ecom_frontend/screens/home/home_screen.dart';
import 'package:provider/provider.dart';

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authStatus = context.watch<AuthProvider>().authStatus;

    switch (authStatus) {
      case AuthStatus.authenticated:
        return const MainScreenWrapper();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}
