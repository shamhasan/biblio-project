import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Data item tab pada [FloatingBottomNav].
@immutable
class FloatingNavItem {
  const FloatingNavItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

/// Bilah navigasi bawah melayang bergaya *Fit-Content Capsule Dock* (`D-013`):
/// - Berukuran *fit-content* (`mainAxisSize: MainAxisSize.min`), tidak memanjang penuh bila tidak dibutuhkan.
/// - Hanya menggunakan ikon garis monokrom (`Icons.*_outlined`) tanpa `menu_book_outlined`.
/// - Label teks diletakkan **di bawah ikon** dan **selalu tampil** baik pada tab yang terpilih maupun tidak terpilih.
/// - Tab yang sedang aktif dibingkai oleh pill kapsul penuh (`borderRadius: radiusFull`) di bagian dalam dock.
class FloatingBottomNav extends StatelessWidget {
  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = defaultItems,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingNavItem> items;

  /// Preset 4 item utama: Beranda (`/`), Rak Buku (`/books`), Pindai (`/scanner`), Setelan (`/settings`).
  static const List<FloatingNavItem> defaultItems = <FloatingNavItem>[
    FloatingNavItem(
      icon: Icons.home_outlined,
      label: 'Beranda',
    ),
    FloatingNavItem(
      icon: Icons.bookmarks_outlined,
      label: 'Rak Buku',
    ),
    FloatingNavItem(
      icon: Icons.qr_code_scanner_outlined,
      label: 'Pindai',
    ),
    FloatingNavItem(
      icon: Icons.settings_outlined,
      label: 'Setelan',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final animDuration = AppTokens.effectiveDuration(
      context,
      duration: AppTokens.motionFast,
    );

    return Container(
      padding: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        border: Border.all(
          color: palette.border,
          width: 1.2,
        ),
        boxShadow: AppTokens.shadowMd(brightness),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(items.length, (index) {
          final item = items[index];
          final isActive = index == currentIndex;

          final pillBgColor = isActive
              ? (isDark ? palette.surfaceAlt : palette.primary)
              : Colors.transparent;
          final pillBorderColor = isActive
              ? (isDark ? palette.border : palette.primary)
              : Colors.transparent;
          final fgColor = isActive
              ? (isDark ? palette.text : palette.onPrimary)
              : palette.textMuted;

          return Semantics(
            button: true,
            selected: isActive,
            label: item.label,
            child: InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              child: AnimatedContainer(
                duration: animDuration,
                constraints: const BoxConstraints(
                  minWidth: 74.0,
                  minHeight: 54.0,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 7.0,
                ),
                decoration: BoxDecoration(
                  color: pillBgColor,
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  border: Border.all(
                    color: pillBorderColor,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      item.icon,
                      size: 20.0,
                      color: fgColor,
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: fgColor,
                            fontSize: 11.0,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                            height: 1.1,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
