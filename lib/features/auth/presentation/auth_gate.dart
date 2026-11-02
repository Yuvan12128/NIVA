import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../navigation/presentation/main_navigation_shell.dart';
import '../data/auth_service.dart';
import 'login_screen.dart';
import 'sign_in_screen.dart';
import 'signup_screen.dart';

/// Gatekeeper widget that routes users based on Firebase Authentication state:
/// - Authenticated -> MainNavigationShell
/// - Unauthenticated -> Minimal Apple-style SignInScreen (with Google Sign-In)
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    this.authStateStream,
    this.authService,
    this.useLegacyEmailAuth = false,
  });

  final Stream<User?>? authStateStream;
  final AuthService? authService;
  final bool useLegacyEmailAuth;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late bool _showLegacyEmail;
  bool _showLogin = true;
  String? _prefilledEmail;

  @override
  void initState() {
    super.initState();
    _showLegacyEmail = widget.useLegacyEmailAuth;
  }

  void _showLoginView([String? email]) {
    setState(() {
      _showLogin = true;
      if (email != null && email.isNotEmpty) {
        _prefilledEmail = email;
      }
    });
  }

  void _showSignUpView() {
    setState(() {
      _showLogin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Stream<User?> stream =
        widget.authStateStream ??
        widget.authService?.authStateChanges ??
        AuthService.instance.authStateChanges;

    return StreamBuilder<User?>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.pureWhite,
            body: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.appleBlue,
                  ),
                ),
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return const MainNavigationShell();
        }

        if (_showLegacyEmail) {
          if (_showLogin) {
            return LoginScreen(
              onNavigateToSignUp: _showSignUpView,
              initialEmail: _prefilledEmail,
              authService: widget.authService,
            );
          }

          return SignUpScreen(
            onNavigateToLogin: _showLoginView,
            authService: widget.authService,
          );
        }

        return SignInScreen(
          authService: widget.authService,
        );
      },
    );
  }
}
