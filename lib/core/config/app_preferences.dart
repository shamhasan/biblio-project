import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import '../theme/app_typography.dart';

/// Wrapper untuk membaca dan menyimpan preferensi pengguna ke `SharedPreferences`
/// sesuai kontrak di `@docs/DATA_MODEL.md`:
/// - `gas_web_app_url`: String (default [ApiConstants.defaultGasWebAppUrl])
/// - `theme_mode`: String (`"light"` atau `"dark"`, default `"light"`)
/// - `font_family`: String (`"sans"` atau `"serif"`, default `"sans"`)
class AppPreferences {
  const AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const String keyGasWebAppUrl = 'gas_web_app_url';
  static const String keyThemeMode = 'theme_mode';
  static const String keyFontFamily = 'font_family';

  String getGasWebAppUrl() {
    final stored = _prefs.getString(keyGasWebAppUrl)?.trim();
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    return ApiConstants.defaultGasWebAppUrl;
  }

  Future<void> setGasWebAppUrl(String url) async {
    await _prefs.setString(keyGasWebAppUrl, url.trim());
  }

  ThemeMode getThemeMode() {
    final raw = _prefs.getString(keyThemeMode);
    if (raw == 'dark') {
      return ThemeMode.dark;
    }
    if (raw == 'light') {
      return ThemeMode.light;
    }
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final String value;
    switch (mode) {
      case ThemeMode.dark:
        value = 'dark';
      case ThemeMode.light:
        value = 'light';
      case ThemeMode.system:
        value = 'system';
    }
    await _prefs.setString(keyThemeMode, value);
  }

  AppFontFamily getFontFamily() {
    final raw = _prefs.getString(keyFontFamily);
    return AppFontFamily.fromStorageKey(raw);
  }

  Future<void> setFontFamily(AppFontFamily fontFamily) async {
    await _prefs.setString(keyFontFamily, fontFamily.storageKey);
  }
}
