import '../config/app_secrets.dart';

/// Konstanta endpoint dan konfigurasi jaringan sesuai `@docs/API_SPEC.md`
/// dan `@docs/INTEGRATIONS.md`.
abstract final class ApiConstants {
  /// Endpoint deployment Google Apps Script Web App bawaan proyek dari [AppSecrets] (`D-010`, `D-011`).
  static String get defaultGasWebAppUrl => AppSecrets.gasWebAppUrl;

  /// Endpoint publik Google Books API (`F-03`).
  static const String googleBooksVolumesUrl =
      'https://www.googleapis.com/books/v1/volumes';

  /// Endpoint publik OpenLibrary Books API sebagai fallback otomatis ketika
  /// Google Books API mencapai batas kuota (`HTTP 429 / 403`) atau mengembalikan hasil kosong (`D-011`).
  static const String openLibraryBooksUrl =
      'https://openlibrary.org/api/books';

  /// Kunci API Google Books dari [AppSecrets] (`D-011`).
  static String get googleBooksApiKey => AppSecrets.googleBooksApiKey;

  /// Batas waktu maksimum untuk seluruh panggilan HTTP (GAS App & Lookup Metadata).
  static const Duration networkTimeout = Duration(seconds: 15);

  /// Content-Type untuk request `POST` ke Google Apps Script Web App.
  static const String gasContentType = 'text/plain;charset=utf-8';
}
