import 'package:ezze_music/ui/theme/app_colors.dart';
import 'package:ezze_music/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme & AppColors Tests', () {
    test('AppTheme.dark generates valid dark ThemeData with custom accent', () {
      const accent = Color(0xFF6366F1);
      final darkTheme = AppTheme.dark(accent);

      expect(darkTheme.brightness, equals(Brightness.dark));
      expect(darkTheme.colorScheme.primary, equals(accent));
      expect(darkTheme.scaffoldBackgroundColor, equals(AppColors.bgDeep));
      expect(darkTheme.sliderTheme.activeTrackColor, equals(accent));
      expect(darkTheme.navigationBarTheme.backgroundColor, equals(AppColors.bgGlass));
    });

    test('AppTheme.light generates valid light ThemeData with custom accent', () {
      const accent = Color(0xFFF43F5E);
      final lightTheme = AppTheme.light(accent);

      expect(lightTheme.brightness, equals(Brightness.light));
      expect(lightTheme.colorScheme.primary, equals(accent));
      expect(lightTheme.sliderTheme.activeTrackColor, equals(accent));
    });

    test('AppColors accent presets are populated and unique', () {
      expect(AppColors.accentPresets, isNotEmpty);
      expect(AppColors.accentPresets.length, greaterThanOrEqualTo(8));
      final uniqueColors = AppColors.accentPresets.map((c) => c.toARGB32()).toSet();
      expect(uniqueColors.length, equals(AppColors.accentPresets.length));
    });

    test('AppColors dynamic switching reflects dark and light palettes correctly', () {
      AppColors.current = AppColors.darkPalette;
      expect(AppColors.isDark, isTrue);
      expect(AppColors.bgDeep, equals(const Color(0xFF09090B)));
      expect(AppColors.textPrimary, equals(const Color(0xFFFAFAFA)));

      AppColors.current = AppColors.lightPalette;
      expect(AppColors.isDark, isFalse);
      expect(AppColors.bgDeep, equals(const Color(0xFFF5F6F8)));
      expect(AppColors.textPrimary, equals(const Color(0xFF18181B)));
      expect(AppColors.divider, equals(const Color(0xFFE2E4E8)));

      // Reset to dark default
      AppColors.current = AppColors.darkPalette;
    });
  });
}
