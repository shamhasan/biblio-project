import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/settings_provider.dart';

/// Layar Setelan Tampilan (`F-13`, rute `/settings`) sesuai `@docs/SCREENS.md`,
/// `@docs/mockup_interaktif_lengkap_final_mvp.html`, dan keputusan `D-010` & `D-012`:
/// - URL GAS App sudah terkonfigurasi otomatis tanpa perlu input manual.
/// - Karena `/settings` termasuk tab utama di `FloatingBottomNav`, tombol Back dihilangkan
///   dan `FloatingBottomNav` ditampilkan di layer `Stack` paling atas oleh `AppNavigationShell`.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space16,
        AppTokens.space12,
        AppTokens.space16,
        98.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Top Header (.top-header — Tab utama navbar tanpa tombol Back sesuai D-012)
          SizedBox(
            height: AppTokens.minTouchTarget,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Setelan Tampilan',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space16),

          // Kartu 1: Tema Tampilan (Ikuti Sistem, Terang, Gelap)
          _SettingsSectionCard(
            title: 'Tema Tampilan',
            subtitle:
                'Sesuaikan kenyamanan latar kertas hangat, mode gelap, atau otomatis mengikuti perangkat.',
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _OptionPillButton(
                    key: const Key('theme_system_button'),
                    icon: Icons.brightness_auto_outlined,
                    title: 'Otomatis',
                    subtitle: 'Ikuti Sistem',
                    isSelected: settings.themeMode == ThemeMode.system,
                    onTap: () => ref
                        .read(settingsProvider.notifier)
                        .updateThemeMode(ThemeMode.system),
                  ),
                ),
                const SizedBox(width: AppTokens.space8),
                Expanded(
                  child: _OptionPillButton(
                    key: const Key('theme_light_button'),
                    icon: Icons.light_mode_outlined,
                    title: 'Terang',
                    subtitle: 'Kertas Hangat',
                    isSelected: settings.themeMode == ThemeMode.light,
                    onTap: () => ref
                        .read(settingsProvider.notifier)
                        .updateThemeMode(ThemeMode.light),
                  ),
                ),
                const SizedBox(width: AppTokens.space8),
                Expanded(
                  child: _OptionPillButton(
                    key: const Key('theme_dark_button'),
                    icon: Icons.dark_mode_outlined,
                    title: 'Gelap',
                    subtitle: 'Arang Hangat',
                    isSelected: settings.themeMode == ThemeMode.dark,
                    onTap: () => ref
                        .read(settingsProvider.notifier)
                        .updateThemeMode(ThemeMode.dark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space12),

          // Kartu 2: Gaya Huruf (Tipografi) (.form-card di mockup HTML)
          _SettingsSectionCard(
            title: 'Gaya Huruf (Tipografi)',
            subtitle:
                'Pilih kenyamanan membaca untuk katalog dan catatan bukumu.',
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _OptionPillButton(
                    key: const Key('font_sans_button'),
                    icon: Icons.text_fields_outlined,
                    title: 'Sans-Serif',
                    subtitle: 'Modern & Ringkas',
                    isSelected: settings.fontFamily == AppFontFamily.sans,
                    onTap: () => ref
                        .read(settingsProvider.notifier)
                        .updateFontFamily(AppFontFamily.sans),
                  ),
                ),
                const SizedBox(width: AppTokens.space8),
                Expanded(
                  child: _OptionPillButton(
                    key: const Key('font_serif_button'),
                    icon: Icons.title_outlined,
                    title: 'Serif Buku',
                    subtitle: 'Klasik & Hangat',
                    isSelected: settings.fontFamily == AppFontFamily.serif,
                    onTap: () => ref
                        .read(settingsProvider.notifier)
                        .updateFontFamily(AppFontFamily.serif),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppTokens.space16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: AppTokens.space12),
          child,
        ],
      ),
    );
  }
}

class _OptionPillButton extends StatelessWidget {
  const _OptionPillButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final bgColor = isSelected ? palette.primary : palette.surfaceAlt;
    final fgColor = isSelected ? palette.onPrimary : palette.text;
    final borderColor = isSelected ? palette.primary : palette.border;
    final duration = AppTokens.effectiveDuration(
      context,
      duration: AppTokens.motionFast,
    );

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title, $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: AnimatedContainer(
          duration: duration,
          constraints: const BoxConstraints(
            minHeight: 54.0,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space8,
            vertical: AppTokens.space8,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 18,
                color: fgColor,
              ),
              const SizedBox(width: AppTokens.space8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: fgColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: fgColor.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
