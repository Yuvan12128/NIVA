import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_gate.dart';

/// Root application widget for NIVA.
/// Routes to AuthGate (Login/SignUp vs MainNavigationShell based on session).
class NivaApp extends StatelessWidget {
  const NivaApp({super.key, this.homeOverride, this.authStateStream});

  final Widget? homeOverride;
  final Stream<User?>? authStateStream;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NIVA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: homeOverride ?? AuthGate(authStateStream: authStateStream),
    );
  }
}
