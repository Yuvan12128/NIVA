import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/splash/presentation/logo_reveal_screen.dart';

/// Root application widget for NIVA.
/// Recreates the native NIVA logo reveal sequence upon launch, then transitions
/// directly to AuthGate (Login/SignUp vs MainNavigationShell based on session).
class NivaApp extends StatefulWidget {
  const NivaApp({
    super.key,
    this.homeOverride,
    this.authStateStream,
    this.showSplash = true,
  });

  final Widget? homeOverride;
  final Stream<User?>? authStateStream;
  final bool showSplash;

  @override
  State<NivaApp> createState() => _NivaAppState();
}

class _NivaAppState extends State<NivaApp> {
  late bool _hasCompletedSplash;

  @override
  void initState() {
    super.initState();
    // Skip splash if an explicit override is provided or showSplash is explicitly disabled
    _hasCompletedSplash = widget.homeOverride != null || !widget.showSplash;
  }

  void _onSplashComplete() {
    if (mounted) {
      setState(() {
        _hasCompletedSplash = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NIVA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home:
          widget.homeOverride ??
          (_hasCompletedSplash
              ? AuthGate(authStateStream: widget.authStateStream)
              : LogoRevealScreen(onComplete: _onSplashComplete)),
    );
  }
}
