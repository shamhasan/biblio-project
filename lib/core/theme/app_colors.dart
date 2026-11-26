import 'package:flutter/material.dart';

/// Palet token warna untuk Mode Terang dan Mode Gelap sesuai `@docs/DESIGN_SYSTEM.md`,
/// `@docs/palet_tipografi_komponen_buku_final.html`, dan `@docs/mockup_interaktif_lengkap_final_mvp.html`.
/// Digunakan sebagai `ThemeExtension` agar widget fitur tidak pernah meng-hardcode hex warna.
@immutable
class AppColorPalette extends ThemeExtension<AppColorPalette> {
  const AppColorPalette({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.text,
    required this.textMuted,
    required this.border,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.error,
    required this.errorBg,
    required this.info,
    required this.infoBg,
  });

  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color text;
  final Color textMuted;
  final Color border;
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color error;
  final Color errorBg;
  final Color info;
  final Color infoBg;

  @override
  AppColorPalette copyWith({
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? accent,
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? text,
    Color? textMuted,
    Color? border,
    Color? success,
    Color? successBg,
    Color? warning,
    Color? warningBg,
    Color? error,
    Color? errorBg,
    Color? info,
    Color? infoBg,
  }) {
    return AppColorPalette(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      error: error ?? this.error,
      errorBg: errorBg ?? this.errorBg,
      info: info ?? this.info,
      infoBg: infoBg ?? this.infoBg,
    );
  }

  @override
  AppColorPalette lerp(ThemeExtension<AppColorPalette>? other, double t) {
    if (other is! AppColorPalette) return this;
    return AppColorPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorBg: Color.lerp(errorBg, other.errorBg, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
    );
  }
}

/// Nada gradien untuk komponen `GeneratedBookCover` (`BR-05`) sesuai HTML palet & mockup.
enum GeneratedCoverTone {
  sage(Color(0xFF1E7D54), Color(0xFF0E5838)),
  terracotta(Color(0xFFB8522E), Color(0xFF7E3117)),
  slate(Color(0xFF2D5D7B), Color(0xFF193A4F)),
  amber(Color(0xFFA46B1D), Color(0xFF6D440E));

  const GeneratedCoverTone(this.gradientStart, this.gradientEnd);

  final Color gradientStart;
  final Color gradientEnd;
}

/// Konstanta token warna aplikasi untuk Light dan Dark mode, skala nuansa (50-900),
/// serta warna khusus komponen sesuai `@docs/palet_tipografi_komponen_buku_final.html`
/// dan `@docs/mockup_interaktif_lengkap_final_mvp.html`.
abstract final class AppColors {
  // Skala Nuansa Primary (Sage Green 50 - 900)
  static const Color primary50 = Color(0xFFF2F7F4);
  static const Color primary100 = Color(0xFFDFECE5);
  static const Color primary200 = Color(0xFFC0D9CC);
  static const Color primary300 = Color(0xFF99BFAD);
  static const Color primary400 = Color(0xFF6E9E88);
  static const Color primary500 = Color(0xFF4B7A65);
  static const Color primary600 = Color(0xFF3E6251);
  static const Color primary700 = Color(0xFF314E40);
  static const Color primary800 = Color(0xFF243A30);
  static const Color primary900 = Color(0xFF17261F);

  // Skala Nuansa Neutral (50 - 900)
  static const Color neutral50 = Color(0xFFFAF6F0);
  static const Color neutral100 = Color(0xFFF1EAE0);
  static const Color neutral200 = Color(0xFFE2D9CC);
  static const Color neutral300 = Color(0xFFC9BEB0);
  static const Color neutral400 = Color(0xFFA3998C);
  static const Color neutral500 = Color(0xFF7D756A);
  static const Color neutral600 = Color(0xFF5E5A54);
  static const Color neutral700 = Color(0xFF3D3A36);
  static const Color neutral800 = Color(0xFF232220);
  static const Color neutral900 = Color(0xFF161615);

  // Token khusus Scanner Viewfinder & Generated Cover
  static const Color viewfinderBackground = Color(0xFF111211);
  static const Color scannerFrameBorder = Color(0xFF84B59F);
  static const Color scannerLaserLine = Color(0xFFF0855E);
  static const Color coverForeground = Color(0xFFFFFFFF);
  static const Color coverSpineOverlay = Color(0x33000000); // rgba(0,0,0,0.20)
  static const Color coverSpineBorder = Color(0x1AFFFFFF); // rgba(255,255,255,0.10)
  static const Color coverRingBorder = Color(0x42FFFFFF); // rgba(255,255,255,0.26)

  static const AppColorPalette light = AppColorPalette(
    primary: Color(0xFF3E6251),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFB34B24),
    onSecondary: Color(0xFFFFFFFF),
    accent: Color(0xFFD99B26),
    background: Color(0xFFFAF6F0),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1EAE0),
    text: Color(0xFF1E1D1B),
    textMuted: Color(0xFF5E5A54),
    border: Color(0xFFE2D9CC),
    success: Color(0xFF2E6F40),
    successBg: Color(0x242E6F40), // rgba(46,111,64,0.14)
    warning: Color(0xFF9A6300),
    warningBg: Color(0x2ED99B26), // rgba(217,155,38,0.18)
    error: Color(0xFFB8332A),
    errorBg: Color(0x24B8332A), // rgba(184,51,42,0.14)
    info: Color(0xFF2B5F82),
    infoBg: Color(0x242B5F82), // rgba(43,95,130,0.14)
  );

  static const AppColorPalette dark = AppColorPalette(
    primary: Color(0xFF84B59F),
    onPrimary: Color(0xFF12211A),
    secondary: Color(0xFFF0855E),
    onSecondary: Color(0xFF261008),
    accent: Color(0xFFF2C14E),
    background: Color(0xFF161615),
    surface: Color(0xFF232220),
    surfaceAlt: Color(0xFF2E2C29),
    text: Color(0xFFF3EFEA),
    textMuted: Color(0xFFACA69E),
    border: Color(0xFF383531),
    success: Color(0xFF6FCF97),
    successBg: Color(0x296FCF97), // rgba(111,207,151,0.16)
    warning: Color(0xFFF2C94C),
    warningBg: Color(0x29F2C94C), // rgba(242,201,76,0.16)
    error: Color(0xFFEB6A62),
    errorBg: Color(0x29EB6A62), // rgba(235,106,98,0.16)
    info: Color(0xFF6CAEE0),
    infoBg: Color(0x296CAEE0), // rgba(108,174,224,0.16)
  );
}

extension AppColorsBuildContext on BuildContext {
  AppColorPalette get appColors =>
      Theme.of(this).extension<AppColorPalette>() ?? AppColors.light;
}
