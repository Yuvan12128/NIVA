import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

/// Lightweight, high-performance native logo reveal animation for NIVA.
/// Recreates the people-connecting brand reveal:
/// 1. Launch background #F8F9FC
/// 2. Left purple/pink figure and right blue/cyan figure appear separately
/// 3. Smooth fade/scale and glide towards the center
/// 4. Connect to visually form the unified NIVA "N" logo
/// 5. Subtle scale-up, soft radial aura glow, and smooth settle
/// 6. Brief hold and navigation callback trigger
///
/// Optimized for low-end Android devices (2 GB / 3 GB RAM) using
/// pure Flutter animation primitives with zero external packages.
class LogoRevealScreen extends StatefulWidget {
  const LogoRevealScreen({
    super.key,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 850),
  });

  /// Callback invoked when the reveal sequence finishes or is skipped.
  final VoidCallback onComplete;

  /// Total duration of the animation sequence (default: 850ms).
  final Duration duration;

  @override
  State<LogoRevealScreen> createState() => _LogoRevealScreenState();
}

class _LogoRevealScreenState extends State<LogoRevealScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Staged animation curves
  late final Animation<double> _elementsFadeIn;
  late final Animation<double> _elementsScaleIn;
  late final Animation<Offset> _leftSlide;
  late final Animation<Offset> _rightSlide;
  late final Animation<double> _elementsFadeOut;
  late final Animation<double> _unifiedLogoFadeIn;
  late final Animation<double> _scaleBounce;
  late final Animation<double> _glowIntensity;
  late final Animation<double> _textFadeIn;

  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    // 1. Elements reveal: 0% to 55% (~0-467ms)
    // Left and right figures fade in and glide inward towards center
    _elementsFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _elementsScaleIn = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _leftSlide = Tween<Offset>(begin: const Offset(-42, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
          ),
        );

    _rightSlide = Tween<Offset>(begin: const Offset(42, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
          ),
        );

    // 2. Connection crossfade: 52% to 64% (~442-544ms)
    // Transition from separate elements to pixel-perfect unified mark
    _elementsFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.52, 0.64, curve: Curves.easeIn),
      ),
    );

    _unifiedLogoFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.52, 0.64, curve: Curves.easeOut),
      ),
    );

    // 3. Connect bounce & settle: 55% to 88% (~467-748ms)
    // Subtle scale-up (1.0 -> 1.06) followed by smooth settle
    _scaleBounce =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 1.0,
              end: 1.06,
            ).chain(CurveTween(curve: Curves.easeOutQuad)),
            weight: 45,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 1.06,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeInOutCubic)),
            weight: 55,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.55, 0.88),
          ),
        );

    // 4. Subtle ambient glow aura: 55% to 90% (~467-765ms)
    // Lightweight radial gradient opacity pulse
    _glowIntensity =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 40,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 1.0,
              end: 0.0,
            ).chain(CurveTween(curve: Curves.easeIn)),
            weight: 60,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.55, 0.90),
          ),
        );

    // 5. NIVA brand wordmark reveal: 60% to 82% (~510-697ms)
    _textFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.82, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handleComplete();
      }
    });

    _controller.forward();
  }

  void _handleComplete() {
    if (_hasCompleted || !mounted) return;
    _hasCompleted = true;
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing: adapts comfortably down to 320px width devices
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = (screenWidth * 0.28).clamp(84.0, 116.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Allow tap-to-skip for instant entry
          onTap: () {
            if (!_hasCompleted) {
              _controller.stop();
              _handleComplete();
            }
          },
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = _scaleBounce.value;
                final glow = _glowIntensity.value;
                final separateOpacity =
                    _elementsFadeIn.value * _elementsFadeOut.value;
                final unifiedOpacity = _unifiedLogoFadeIn.value;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Main Mark Container with Scale & Glow
                    Transform.scale(
                      scale: scale,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // 1. Subtle, lightweight radial glow aura (no heavy shaders)
                          if (glow > 0.01)
                            Container(
                              width: logoSize * 1.5,
                              height: logoSize * 1.5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.primaryPurple.withValues(
                                      alpha: (0.20 * glow).clamp(0.0, 1.0),
                                    ),
                                    AppColors.blue.withValues(
                                      alpha: (0.10 * glow).clamp(0.0, 1.0),
                                    ),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.55, 1.0],
                                ),
                              ),
                            ),

                          // 2. Sized Logo Stage
                          SizedBox(
                            width: logoSize,
                            height: logoSize,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Separate Left & Right Elements gliding towards center
                                if (separateOpacity > 0.01)
                                  Opacity(
                                    opacity: separateOpacity.clamp(0.0, 1.0),
                                    child: Transform.scale(
                                      scale: _elementsScaleIn.value,
                                      child: Stack(
                                        children: [
                                          // Left Purple/Pink Figure
                                          Transform.translate(
                                            offset: _leftSlide.value,
                                            child: Image.asset(
                                              'assets/images/niva_anim_left.png',
                                              width: logoSize,
                                              height: logoSize,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          // Right Blue/Cyan Figure
                                          Transform.translate(
                                            offset: _rightSlide.value,
                                            child: Image.asset(
                                              'assets/images/niva_anim_right.png',
                                              width: logoSize,
                                              height: logoSize,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Unified Formed NIVA "N" Logo
                                if (unifiedOpacity > 0.01)
                                  Opacity(
                                    opacity: unifiedOpacity.clamp(0.0, 1.0),
                                    child: Image.asset(
                                      'assets/images/niva_mark.png',
                                      width: logoSize,
                                      height: logoSize,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // 3. NIVA brand wordmark reveal
                    Opacity(
                      opacity: _textFadeIn.value.clamp(0.0, 1.0),
                      child: const Text(
                        'NIVA',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontFamilyFallback: AppTextStyles.fontFallbacks,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryPurple,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
