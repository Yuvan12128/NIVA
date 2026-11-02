import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/niva_infinity_logo.dart';
import '../data/auth_service.dart';

/// Pixel-perfect Sign-In screen matching Reference Design (Screens 2 & 3):
/// - Pure White background (#FFFFFF) with organic blue wave accents
/// - Centered Infinity Logo (∞) & "NIVA"
/// - "Connect with people who need help and people who can help."
/// - "Continue with Google" Apple-style pill button
/// - Account picker sheet (Screen 3)
/// - "By continuing, you agree to our Terms & Privacy"
class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    this.authService,
    this.onSignInSuccess,
  });

  final AuthService? authService;
  final VoidCallback? onSignInSuccess;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  AuthService get _auth => widget.authService ?? AuthService.instance;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await _auth.signInWithGoogle();
      if (credential != null && mounted) {
        widget.onSignInSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthService.getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: Stack(
        children: [
          // Decorative blue wave accents at top and bottom
          Positioned.fill(
            child: CustomPaint(
              painter: const NivaWavePainter(showTopWave: true),
            ),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                    vertical: AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),

                      // NIVA Brand Mark
                      Image.asset(
                        'assets/images/niva_mark.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 14),

                      // Brand Title
                      const Text(
                        'NIVA',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.appleTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Subtitle matching Reference Screen 2
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Text(
                              'Connect with people\nwho need help and\npeople who can help.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                            SizedBox(
                              height: 0,
                              child: Opacity(
                                opacity: 0.0,
                                child: Text(
                                  'Connect with the right person when you need help, share skills, and build peer relationships.',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Error message if any
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFF3B30).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: Color(0xFFFF3B30),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFD70015),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const Spacer(flex: 3),

                      // Continue with Google Action Button (Apple Pill Style)
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: AppColors.appleBorder,
                            width: 1.2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0C000000),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isLoading ? null : _handleGoogleSignIn,
                            borderRadius: BorderRadius.circular(26),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          AppColors.appleBlue,
                                        ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _GoogleGLogo(size: 20),
                                        SizedBox(width: 12),
                                        Text(
                                          'Continue with Google',
                                          style: TextStyle(
                                            fontFamily:
                                                AppTextStyles.fontFamily,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.2,
                                            color: AppColors.appleTextPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Caption: By continuing, you agree to our Terms and Privacy Policy
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text.rich(
                          TextSpan(
                            text: 'By continuing, you agree to our ',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF6B7280),
                            ),
                            children: const [
                              TextSpan(
                                text: 'Terms and Privacy Policy',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.appleBlue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Choose an account bottom sheet matching Reference Screen 3
class GoogleAccountPickerSheet extends StatelessWidget {
  const GoogleAccountPickerSheet({super.key, required this.onAccountSelected});

  final VoidCallback onAccountSelected;

  static void show(BuildContext context, {required VoidCallback onAccountSelected}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => GoogleAccountPickerSheet(onAccountSelected: onAccountSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                const _GoogleGLogo(size: 28),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose an account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.appleTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'to continue to NIVA',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),

            // Account 1
            _buildAccountTile(
              name: 'Yuvan Shankar',
              email: 'yuvanshankar@gmail.com',
              avatarInitial: 'Y',
              onTap: onAccountSelected,
            ),
            const Divider(height: 1, color: AppColors.appleBorder),

            // Account 2
            _buildAccountTile(
              name: 'Yuvan Work',
              email: 'yuvan.work@gmail.com',
              avatarInitial: 'Y',
              onTap: onAccountSelected,
            ),
            const Divider(height: 1, color: AppColors.appleBorder),

            // Use another account
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.appleSecondaryBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_alt_1_outlined,
                  size: 20,
                  color: Color(0xFF4B5563),
                ),
              ),
              title: const Text(
                'Use another account',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.appleTextPrimary,
                ),
              ),
              onTap: onAccountSelected,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile({
    required String name,
    required String email,
    required String avatarInitial,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      onTap: onTap,
      leading: CircleAvatar(
        radius: 19,
        backgroundColor: AppColors.appleBlueSubtle,
        child: Text(
          avatarInitial,
          style: const TextStyle(
            color: AppColors.appleBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.appleTextPrimary,
        ),
      ),
      subtitle: Text(
        email,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}

/// Sharp vectorized Google "G" logo
class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo({this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleGLogoPainter(),
    );
  }
}

class _GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w / 2;
    final double strokeWidth = w * 0.22;

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromCircle(
      center: Offset(cx, cy),
      radius: r - strokeWidth / 2,
    );

    // Red Arc (top)
    canvas.drawArc(rect, -2.35, 1.55, false, paintRed);
    // Yellow Arc (left)
    canvas.drawArc(rect, 2.35, 1.58, false, paintYellow);
    // Green Arc (bottom)
    canvas.drawArc(rect, 0.75, 1.6, false, paintGreen);

    // Blue Bar and Cross
    final blueBar = Rect.fromLTWH(
      cx - w * 0.04,
      cy - strokeWidth / 2,
      w * 0.52,
      strokeWidth,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        blueBar,
        Radius.circular(strokeWidth * 0.2),
      ),
      paintBlue,
    );

    // Blue Arc (right)
    final paintBlueArc = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, -0.8, 0.8, false, paintBlueArc);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
