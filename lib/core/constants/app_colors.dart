import 'package:flutter/material.dart';

/// Design tokens for NIVA color palette.
/// Follows NIVA Mobile App UX Design System specification.
abstract final class AppColors {
  // Apple Minimal Design System Tokens (Phase 1 & 2 - Final Reference)
  static const Color appleBlue = Color(0xFF007AFF);
  static const Color appleBluePressed = Color(0xFF0062CC);
  static const Color appleBlueSubtle = Color(0xFFEBF5FF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color appleSecondaryBg = Color(0xFFF2F2F7);
  static const Color appleTextPrimary = Color(0xFF1D1D1F);
  static const Color appleTextSecondary = Color(0xFF86868B);
  static const Color appleTextTertiary = Color(0xFFA1A1A6);
  static const Color appleBorder = Color(0xFFE5E5EA);

  // Intent Card & Badge Tints (Reference Design)
  static const Color needCardBg = Color(0xFFF0F6FF);
  static const Color needCardBorder = Color(0xFFD9E8FF);
  static const Color canHelpCardBg = Color(0xFFF0FDF4);
  static const Color canHelpCardBorder = Color(0xFFD2F4DC);
  static const Color badgeGreenBg = Color(0xFFE8F8EE);
  static const Color badgeGreenText = Color(0xFF16A34A);
  static const Color badgeBlueBg = Color(0xFFEBF5FF);
  static const Color badgeBlueText = Color(0xFF007AFF);

  // Brand Colors (Aligned with Apple Blue design)
  static const Color primaryPurple = Color(0xFF007AFF); // Re-targeted to Apple Blue
  static const Color primaryDeep = Color(0xFF0062CC);
  static const Color primaryFixed = Color(0xFFEBF5FF);
  static const Color onPrimaryFixed = Color(0xFF00479C);
  static const Color secondaryPurple = Color(0xFF007AFF);
  static const Color secondaryFixed = Color(0xFFEBF5FF);
  static const Color blue = Color(0xFF007AFF);
  static const Color tertiary = Color(0xFF00479C);
  static const Color tertiaryFixed = Color(0xFFD8E2FF);

  // Surface & Canvas (Pure white Apple baseline)
  static const Color background = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF8FAFC);
  static const Color surfaceMuted = Color(0xFFF2F2F7);
  static const Color surfaceHigh = Color(0xFFE5E5EA);
  static const Color surfaceHighest = Color(0xFFD1D1D6);

  // Text Colors
  static const Color textPrimary = Color(0xFF1D1D1F);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderSubtle = Color(0xFFE5E5EA);

  // Semantic Status
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);

  // Category Accent Colors & Tints
  static const Color peopleIcon = Color(0xFF007AFF);
  static const Color peopleBg = Color(0xFFEBF5FF);

  static const Color servicesIcon = Color(0xFF007AFF);
  static const Color servicesBg = Color(0xFFEBF5FF);

  static const Color infoIcon = Color(0xFF007AFF);
  static const Color infoBg = Color(0xFFEBF5FF);

  static const Color opportunitiesIcon = Color(0xFF007AFF);
  static const Color opportunitiesBg = Color(0xFFEBF5FF);

  static const Color communitiesIcon = Color(0xFF007AFF);
  static const Color communitiesBg = Color(0xFFEBF5FF);

  static const Color helpIcon = Color(0xFF16A34A);
  static const Color helpBg = Color(0xFFDCFCE7);
}
