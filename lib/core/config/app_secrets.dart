import 'app_secrets.local.dart';

/// Penyedia kredensial aplikasi yang membaca variabel `--dart-define` terlebih dahulu
/// lalu melakukan fallback ke `LocalAppSecrets` (`lib/core/config/app_secrets.local.dart` yang di-gitignore).
abstract final class AppSecrets {
  static const String _envGoogleBooksKey = String.fromEnvironment(
    'GOOGLE_BOOKS_API_KEY',
  );

  static const String _envGasWebAppUrl = String.fromEnvironment(
    'GAS_WEB_APP_URL',
  );

  /// Kunci Google Books API (`D-011`).
  static String get googleBooksApiKey {
    if (_envGoogleBooksKey.trim().isNotEmpty) {
      return _envGoogleBooksKey.trim();
    }
    return LocalAppSecrets.googleBooksApiKey.trim();
  }

  /// URL deployment Google Apps Script Web App bawaan (`D-010`).
  static String get gasWebAppUrl {
    if (_envGasWebAppUrl.trim().isNotEmpty) {
      return _envGasWebAppUrl.trim();
    }
    return LocalAppSecrets.gasWebAppUrl.trim();
  }
}
