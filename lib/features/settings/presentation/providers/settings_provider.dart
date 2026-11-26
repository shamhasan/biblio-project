import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/app_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_typography.dart';

/// Provider untuk instance [SharedPreferences] yang di-override pada `ProviderScope` di `main.dart`.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider wajib di-override di ProviderScope (main.dart).',
  );
});

/// Provider untuk [AppPreferences] wrapper.
final appPreferencesProvider = Provider<AppPreferences>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppPreferences(prefs);
});

/// State imutabel untuk preferensi aplikasi (`F-13`, `@docs/DATA_MODEL.md`).
@immutable
class SettingsState {
  const SettingsState({
    this.gasWebAppUrl = '',
    this.themeMode = ThemeMode.system,
    this.fontFamily = AppFontFamily.sans,
  });

  final String gasWebAppUrl;
  final ThemeMode themeMode;
  final AppFontFamily fontFamily;

  bool get hasGasUrl => gasWebAppUrl.trim().isNotEmpty;

  SettingsState copyWith({
    String? gasWebAppUrl,
    ThemeMode? themeMode,
    AppFontFamily? fontFamily,
  }) {
    return SettingsState(
      gasWebAppUrl: gasWebAppUrl ?? this.gasWebAppUrl,
      themeMode: themeMode ?? this.themeMode,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettingsState &&
        other.gasWebAppUrl == gasWebAppUrl &&
        other.themeMode == themeMode &&
        other.fontFamily == fontFamily;
  }

  @override
  int get hashCode => Object.hash(gasWebAppUrl, themeMode, fontFamily);
}

/// Notifier untuk membaca dan memperbarui preferensi tema Terang/Gelap,
/// jenis huruf Sans-Serif / Serif Buku, serta URL GAS App bawaan (`F-13`, `D-010`).
class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final appPrefs = ref.watch(appPreferencesProvider);
    return SettingsState(
      gasWebAppUrl: appPrefs.getGasWebAppUrl(),
      themeMode: appPrefs.getThemeMode(),
      fontFamily: appPrefs.getFontFamily(),
    );
  }

  Future<void> updateGasWebAppUrl(String url) async {
    final trimmed = url.trim();
    final effective = trimmed.isEmpty
        ? ApiConstants.defaultGasWebAppUrl
        : trimmed;
    final appPrefs = ref.read(appPreferencesProvider);
    await appPrefs.setGasWebAppUrl(effective);
    state = state.copyWith(gasWebAppUrl: effective);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final appPrefs = ref.read(appPreferencesProvider);
    await appPrefs.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> toggleThemeMode() async {
    final nextMode = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await updateThemeMode(nextMode);
  }

  Future<void> updateFontFamily(AppFontFamily fontFamily) async {
    final appPrefs = ref.read(appPreferencesProvider);
    await appPrefs.setFontFamily(fontFamily);
    state = state.copyWith(fontFamily: fontFamily);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
