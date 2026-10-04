import 'package:flutter/material.dart';

/// Context-aware palette tokens supporting dark and light themes seamlessly.
class AppPalette {
  final Color bgDeep;
  final Color bgSurface;
  final Color bgGlass;
  final Color bgElevated;
  final Color divider;
  final Color borderSubtle;
  final Color borderGlass;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDim;
  final bool isDark;

  const AppPalette({
    required this.bgDeep,
    required this.bgSurface,
    required this.bgGlass,
    required this.bgElevated,
    required this.divider,
    required this.borderSubtle,
    required this.borderGlass,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDim,
    required this.isDark,
  });

  BoxDecoration glassCard({BorderRadiusGeometry? borderRadius, Border? border}) {
    return BoxDecoration(
      color: bgGlass,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: border ?? Border.all(color: divider),
    );
  }

  BoxDecoration radialBackground(Color accent) {
    return BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(0, -0.4),
        radius: 1.1,
        colors: [
          isDark
              ? accent.withValues(alpha: 0.12)
              : accent.withValues(alpha: 0.08),
          bgDeep,
        ],
      ),
    );
  }
}

/// Centralized design tokens and color palette for EzzeMusic.
class AppColors {
  AppColors._();

  // ── Active Theme State ─────────────────────────────────────────
  static AppPalette current = darkPalette;

  static Color get bgDeep => current.bgDeep;
  static Color get bgSurface => current.bgSurface;
  static Color get bgGlass => current.bgGlass;
  static Color get bgElevated => current.bgElevated;

  static Color get divider => current.divider;
  static Color get borderSubtle => current.borderSubtle;
  static Color get borderGlass => current.borderGlass;

  static Color get textPrimary => current.textPrimary;
  static Color get textSecondary => current.textSecondary;
  static Color get textMuted => current.textMuted;
  static Color get textDim => current.textDim;
  static bool get isDark => current.isDark;

  // ── Preset Palettes ───────────────────────────────────────────
  static const AppPalette darkPalette = AppPalette(
    bgDeep: Color(0xFF09090B),
    bgSurface: Color(0xFF121215),
    bgGlass: Color(0xFF18181B),
    bgElevated: Color(0xFF222228),
    divider: Color(0xFF27272A),
    borderSubtle: Color(0x1AFFFFFF),
    borderGlass: Color(0x2EFFFFFF),
    textPrimary: Color(0xFFFAFAFA),
    textSecondary: Color(0xFFA1A1AA),
    textMuted: Color(0xFF71717A),
    textDim: Color(0xFF52525B),
    isDark: true,
  );

  static const AppPalette lightPalette = AppPalette(
    bgDeep: Color(0xFFF5F6F8),
    bgSurface: Color(0xFFFFFFFF),
    bgGlass: Color(0xFFFFFFFF),
    bgElevated: Color(0xFFEBECEF),
    divider: Color(0xFFE2E4E8),
    borderSubtle: Color(0x14000000), // ~8% black
    borderGlass: Color(0x1F000000), // ~12% black
    textPrimary: Color(0xFF18181B),
    textSecondary: Color(0xFF52525B),
    textMuted: Color(0xFF71717A),
    textDim: Color(0xFFA1A1AA),
    isDark: false,
  );

  /// Resolves the current theme palette dynamically based on the build context
  static AppPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkPalette : lightPalette;
  }

  // ── Curated Accent Palette Presets ──────────────────────────────
  static const Color defaultAccent = Color(0xFF6366F1); // Electric Indigo
  static const List<Color> accentPresets = [
    Color(0xFF6366F1), // Indigo
    Color(0xFFF43F5E), // Rose
    Color(0xFFD4AF37), // Luxury Gold
    Color(0xFF10B981), // Emerald
    Color(0xFF0EA5E9), // Sky Cyan
    Color(0xFF8B5CF6), // Violet
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF4044FA), // Cobalt Blue
  ];
}

extension AppPaletteContext on BuildContext {
  AppPalette get colors => AppColors.of(this);
}
