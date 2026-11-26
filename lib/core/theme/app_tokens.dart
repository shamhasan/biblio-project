import 'package:flutter/material.dart';

/// Token spasi, radius sudut, bayangan (shadows), dimensi sampul buku, dan durasi animasi
/// sesuai `@docs/DESIGN_SYSTEM.md`, `@docs/palet_tipografi_komponen_buku_final.html`,
/// dan `@docs/mockup_interaktif_lengkap_final_mvp.html`.
abstract final class AppTokens {
  // Spasi (kelipatan 4 dp)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // Radius sudut
  static const double radiusSm = 8.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 22.0;
  static const double radiusFull = 999.0;

  // Radius asimetris sampul buku (punggung kiri lebih tegas, sisi buka kanan lebih membulat)
  static const BorderRadius coverRadiusSmallMedium = BorderRadius.only(
    topLeft: Radius.circular(7.0),
    bottomLeft: Radius.circular(7.0),
    topRight: Radius.circular(11.0),
    bottomRight: Radius.circular(11.0),
  );

  static const BorderRadius coverRadiusLarge = BorderRadius.only(
    topLeft: Radius.circular(9.0),
    bottomLeft: Radius.circular(9.0),
    topRight: Radius.circular(15.0),
    bottomRight: Radius.circular(15.0),
  );

  // Dimensi komponen BookCoverView & GeneratedBookCover sesuai mockup
  static const Size coverSizeSmall = Size(54.0, 78.0);
  static const Size coverSizeMedium = Size(68.0, 98.0);
  static const Size coverSizeLarge = Size(118.0, 168.0);

  // Target sentuh minimum aksesibilitas (WCAG AA)
  static const double minTouchTarget = 44.0;
  static const double chipHeight = 36.0;
  static const double bottomNavHeight = 62.0;

  // Durasi animasi
  static const Duration motionFast = Duration(milliseconds: 160);
  static const Duration motionBase = Duration(milliseconds: 260);

  /// Bayangan kartu kecil (`--shadow-sm`) sesuai mode Terang/Gelap di mockup HTML.
  static List<BoxShadow> shadowSm(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return <BoxShadow>[
      BoxShadow(
        color: isDark
            ? const Color(0x59000000) // rgba(0,0,0,0.35)
            : const Color(0x0F1E1D1B), // rgba(30,29,27,0.06)
        offset: const Offset(0, 2),
        blurRadius: 6,
      ),
    ];
  }

  /// Bayangan kartu utama / floating navbar (`--shadow-md`) sesuai mode Terang/Gelap di mockup HTML.
  static List<BoxShadow> shadowMd(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return <BoxShadow>[
      BoxShadow(
        color: isDark
            ? const Color(0x73000000) // rgba(0,0,0,0.45)
            : const Color(0x1A1E1D1B), // rgba(30,29,27,0.10)
        offset: const Offset(0, 8),
        blurRadius: 20,
      ),
    ];
  }

  /// Bayangan khusus sampul buku (`0 4px 12px rgba(0,0,0,.16)`).
  static const List<BoxShadow> coverShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x29000000),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  /// Mengembalikan `Duration.zero` apabila pengaturan sistem *Reduce Motion* aktif.
  static Duration effectiveDuration(
    BuildContext context, {
    Duration duration = motionBase,
  }) {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return disableAnimations ? Duration.zero : duration;
  }
}
