/// Contoh template konfigurasi kredensial lokal (`app_secrets.local.dart`).
/// Salin file ini menjadi `app_secrets.local.dart` dan isi dengan API Key pribadi Anda.
abstract final class LocalAppSecretsExample {
  static const String googleBooksApiKey = 'YOUR_GOOGLE_BOOKS_API_KEY';

  static const String gasWebAppUrl =
      'https://script.google.com/macros/s/YOUR_DEPLOYMENT_ID/exec';
}
