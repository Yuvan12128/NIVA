import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/niva_button.dart';
import '../data/auth_service.dart';

/// Sign Up screen matching the NIVA design system specification.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    required this.onNavigateToLogin,
    this.authService,
  });

  final void Function([String? email]) onNavigateToLogin;
  final AuthService? authService;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _cityController = TextEditingController(
    text: 'Chennai',
  );

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  AuthService get _auth => widget.authService ?? AuthService.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final city = _cityController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please complete your name, email, and password.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _auth.signUpWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
        city: city.isNotEmpty ? city : 'Chennai',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthService.getErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  // NIVA Branding & Title
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/niva_mark.png',
                        height: 36,
                        width: 36,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Text(
                        'NIVA',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontFamilyFallback: AppTextStyles.fontFallbacks,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryPurple,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text('Create your account', style: AppTextStyles.h2),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Join NIVA and discover solutions for your needs.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Error Banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(color: AppColors.error, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AppTextStyles.captionSmall.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_errorMessage ==
                              'An account already exists for this email address.') ...[
                            const SizedBox(height: AppSpacing.sm),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primaryPurple,
                                  side: const BorderSide(
                                    color: AppColors.primaryPurple,
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppSpacing.borderRadiusSm,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.login_rounded, size: 16),
                                label: const Text(
                                  'Sign in to this account',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                onPressed: () {
                                  widget.onNavigateToLogin(
                                    _emailController.text.trim(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Full Name Field
                  const Text('Full Name', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Arun Kumar',
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Email Field
                  const Text('Email Address', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(
                      hintText: 'name@example.com',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Location Field
                  const Text(
                    'Approximate City / Region',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _cityController,
                    textInputAction: TextInputAction.next,
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Chennai or Remote',
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Password Field
                  const Text('Password', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleSignUp(),
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'At least 6 characters',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textTertiary,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Create Account CTA
                  NivaButton(
                    label: 'Create Account',
                    isFullWidth: true,
                    isLoading: _isLoading,
                    onPressed: _handleSignUp,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Switch to Login
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigateToLogin(
                            _emailController.text.trim(),
                          ),
                          child: const Text('Sign In'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
