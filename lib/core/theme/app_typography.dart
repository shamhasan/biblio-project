import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Pilihan jenis huruf aplikasi yang dapat diganti pengguna (`F-13`).
enum AppFontFamily {
  /// Plus Jakarta Sans (Default)
  sans('sans', 'Plus Jakarta Sans', <String>['sans-serif', 'Roboto']),

  /// Lora (Serif Buku)
  serif('serif', 'Lora', <String>['serif', 'Georgia']);

  const AppFontFamily(this.storageKey, this.displayName, this.fallbackFamilies);

  final String storageKey;
  final String displayName;
  final List<String> fallbackFamilies;

  static AppFontFamily fromStorageKey(String? value) {
    if (value == serif.storageKey) {
      return AppFontFamily.serif;
    }
    return AppFontFamily.sans;
  }
}

/// Pembangun `TextTheme` sesuai skala ukuran `@docs/DESIGN_SYSTEM.md`:
/// `xs: 12sp`, `sm: 14sp`, `base: 16sp`, `lg: 18sp`, `xl: 20sp`, `2xl: 24sp`.
abstract final class AppTypography {
  static const double sizeXs = 12.0;
  static const double sizeSm = 14.0;
  static const double sizeBase = 16.0;
  static const double sizeLg = 18.0;
  static const double sizeXl = 20.0;
  static const double size2Xl = 24.0;

  /// Bila disetel `false` (mis. pada lingkungan widget test tanpa bundel `.ttf`),
  /// `buildTextTheme` akan menggunakan nama `fontFamily` dan `fontFamilyFallback`
  /// secara langsung tanpa memicu exception aset `google_fonts`.
  static bool useGoogleFontsLoader = true;

  static TextTheme buildTextTheme({
    required AppFontFamily fontFamily,
    required AppColorPalette palette,
  }) {
    final baseTheme = TextTheme(
      headlineLarge: TextStyle(
        fontSize: size2Xl,
        fontWeight: FontWeight.w700,
        color: palette.text,
        height: 1.25,
        fontFamilyFallback: fontFamily.fallbackFamilies,
      ),
      headlineMedium: TextStyle(
        fontSize: sizeXl,
        fontWeight: FontWeight.w700,
        color: palette.text,
        height: 1.3,
        fontFamilyFallback: fontFamily.fallbackFamilies,
      ),
      titleLarge: TextStyle(
        fontSize: sizeLg,
        fontWeight: FontWeight.w600,
        color: palette.text,
        height: 1.35,
        fontFamilyFallback: fontFamily.fallbackFamilies,
      ),
      titleMedium: TextStyle(
        fontSize: sizeBase,
        fontWeight: FontWeight.w600,
        color: palette.text,
        height: 1.4,
        fontFamilyFallback: fontFamily.fallbackFamilies,
      ),
      titleSmall: TextStyle(
        fontSize: sizeSm,
        fontWeight: FontWeight.w600,
        color: palette.text,
        height: 1.4,
        fontFamilyFallback: fontFamily.fallbackFamilies,
      ),
      bodyLarge: TextStyle(
        fontSize: sizeBase,
        fontWeight: FontWeight.w400,
        color: palette.text,
        height: 1.5,
        fontFamilyFallback: fontFamily.fallbackFamilies,
      ),
      bodyMedium: TextStyle(
        fontSize: sizeSm,
        fontWeight: FontWeight.w400,
        color: palette.text,
        height: 1.45,
        fontFamilyFallback: fontFamily.fallbackFamilies,
      ),
      bodySmall: TextStyle(
        fontSize: sizeXs,
        fontWeight: FontWeight.w400,
        color: palette.textMuted,
        height: 1.4,
        fontFamilyFallback: fontFamily.fallbackFamilies,
      ),
      labelLarge: TextStyle(
        fontSize: sizeSm,
        fontWeight: FontWeight.w600,
        color: palette.text,
        height: 1.2,
        fontFamilyFallback: fontFamily.fallbackFamilies,
      ),
      labelMedium: TextStyle(
        fontSize: sizeXs,
        fontWeight: FontWeight.w600,
        color: palette.textMuted,
        height: 1.2,
        fontFamilyFallback: fontFamily.fallbackFamilies,
      ),
      labelSmall: TextStyle(
        fontSize: sizeXs,
        fontWeight: FontWeight.w500,
        color: palette.textMuted,
        height: 1.2,
        fontFamilyFallback: fontFamily.fallbackFamilies,
      ),
    );

    if (!useGoogleFontsLoader || !GoogleFonts.config.allowRuntimeFetching) {
      return baseTheme.apply(
        fontFamily: fontFamily.displayName,
        fontFamilyFallback: fontFamily.fallbackFamilies,
      );
    }

    switch (fontFamily) {
      case AppFontFamily.sans:
        return GoogleFonts.plusJakartaSansTextTheme(baseTheme);
      case AppFontFamily.serif:
        return GoogleFonts.loraTextTheme(baseTheme);
    }
  }
}
