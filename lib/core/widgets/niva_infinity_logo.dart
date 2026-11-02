import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pixel-perfect vectorized NIVA Infinity Logo (`∞`)
/// Rendered using Bernoulli lemniscate mathematics with vivid Apple Blue gradient.
class NivaInfinityLogo extends StatelessWidget {
  const NivaInfinityLogo({
    super.key,
    this.width = 84,
    this.height = 46,
    this.strokeWidth,
    this.gradientColors,
  });

  final double width;
  final double height;
  final double? strokeWidth;
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        size: Size(width, height),
        painter: _InfinityLogoPainter(
          strokeWidth: strokeWidth ?? (width * 0.18),
          gradientColors: gradientColors ??
              const [
                Color(0xFF007AFF), // Apple Blue
                Color(0xFF0091FF), // Vivid Azure
                Color(0xFF00B4D8), // Cyan hint
              ],
        ),
      ),
    );
  }
}

class _InfinityLogoPainter extends CustomPainter {
  const _InfinityLogoPainter({
    required this.strokeWidth,
    required this.gradientColors,
  });

  final double strokeWidth;
  final List<Color> gradientColors;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // Radius scaling for lemniscate: leave padding for stroke width
    final double scaleX = (size.width - strokeWidth) / 2;
    final double scaleY = (size.height - strokeWidth);

    final path = Path();
    const int steps = 120;

    for (int i = 0; i <= steps; i++) {
      final double t = (i / steps) * 2 * math.pi;
      final double sinT = math.sin(t);
      final double cosT = math.cos(t);
      final double denom = 1 + sinT * sinT;

      final double x = cx + scaleX * (cosT / denom);
      final double y = cy + scaleY * ((sinT * cosT) / denom);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _InfinityLogoPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gradientColors != gradientColors;
  }
}

/// Subtle Apple-inspired bottom wave decoration for Splash and Sign In screens.
class NivaWavePainter extends CustomPainter {
  const NivaWavePainter({this.showTopWave = false});

  final bool showTopWave;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Bottom soft blue organic wave
    final bottomPath1 = Path();
    bottomPath1.moveTo(0, size.height * 0.85);
    bottomPath1.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.76,
      size.width * 0.70,
      size.height * 0.88,
    );
    bottomPath1.quadraticBezierTo(
      size.width * 0.88,
      size.height * 0.94,
      size.width,
      size.height * 0.92,
    );
    bottomPath1.lineTo(size.width, size.height);
    bottomPath1.lineTo(0, size.height);
    bottomPath1.close();

    final paint1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x3370B4FF),
          Color(0x66007AFF),
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.75, size.width, size.height * 0.25));
    canvas.drawPath(bottomPath1, paint1);

    final bottomPath2 = Path();
    bottomPath2.moveTo(0, size.height * 0.89);
    bottomPath2.quadraticBezierTo(
      size.width * 0.40,
      size.height * 0.82,
      size.width * 0.78,
      size.height * 0.93,
    );
    bottomPath2.lineTo(size.width, size.height);
    bottomPath2.lineTo(0, size.height);
    bottomPath2.close();

    final paint2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x4D007AFF),
          Color(0x990062CC),
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.80, size.width, size.height * 0.20));
    canvas.drawPath(bottomPath2, paint2);

    // 2. Optional top-right subtle wave for Sign-In screen
    if (showTopWave) {
      final topPath = Path();
      topPath.moveTo(size.width * 0.65, 0);
      topPath.quadraticBezierTo(
        size.width * 0.80,
        size.height * 0.08,
        size.width,
        size.height * 0.06,
      );
      topPath.lineTo(size.width, 0);
      topPath.close();

      final topPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0x40007AFF),
            Color(0x1060A5FA),
          ],
        ).createShader(Rect.fromLTWH(size.width * 0.60, 0, size.width * 0.40, size.height * 0.10));
      canvas.drawPath(topPath, topPaint);
    }
  }

  @override
  bool shouldRepaint(covariant NivaWavePainter oldDelegate) =>
      oldDelegate.showTopWave != showTopWave;
}
