import 'package:flutter/material.dart';

/// Design tokens for NIVA color palette.
/// Follows NIVA Mobile App UX Design System specification.
abstract final class AppColors {
  // Brand Colors
  static const Color primaryPurple = Color(0xFF5B4BDB);
  static const Color primaryDeep = Color(0xFF422EC2);
  static const Color primaryFixed = Color(0xFFE4DFFF);
  static const Color onPrimaryFixed = Color(0xFF150066);
  static const Color secondaryPurple = Color(0xFF6C63FF);
  static const Color secondaryFixed = Color(0xFFE3DFFF);
  static const Color blue = Color(0xFF3B82F6);
  static const Color tertiary = Color(0xFF00479C);
  static const Color tertiaryFixed = Color(0xFFD8E2FF);

  // Surface & Canvas (Stitch design system)
  static const Color background = Color(0xFFFCF8FF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF5F2FF);
  static const Color surfaceMuted = Color(0xFFEFECFF);
  static const Color surfaceHigh = Color(0xFFE9E6FA);
  static const Color surfaceHighest = Color(0xFFE3E0F4);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A28);
  static const Color textSecondary = Color(0xFF474554);
  static const Color textTertiary = Color(0xFF787586);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderSubtle = Color(0xFFC8C4D7);

  // Semantic Status
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);

  // Category Accent Colors & Tints
  static const Color peopleIcon = Color(0xFFEF4444);
  static const Color peopleBg = Color(0xFFFEE2E2);

  static const Color servicesIcon = Color(0xFF7C3AED);
  static const Color servicesBg = Color(0xFFEDE9FE);

  static const Color infoIcon = Color(0xFF2563EB);
  static const Color infoBg = Color(0xFFDBEAFE);

  static const Color opportunitiesIcon = Color(0xFF0284C7);
  static const Color opportunitiesBg = Color(0xFFE0F2FE);

  static const Color communitiesIcon = Color(0xFF9333EA);
  static const Color communitiesBg = Color(0xFFF3E8FF);

  static const Color helpIcon = Color(0xFF16A34A);
  static const Color helpBg = Color(0xFFDCFCE7);
}
