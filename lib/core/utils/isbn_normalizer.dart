/// Utilitas normalisasi dan validasi nomor ISBN-10 / ISBN-13 sesuai aturan bisnis `BR-01`
/// dan `@docs/DATA_MODEL.md`:
/// - Menghapus seluruh karakter non-alfanumerik (`-`, spasi, titik, dll.).
/// - Mengubah huruf `x` kecil menjadi `X` kapital (untuk digit checksum ISBN-10).
/// - Memvalidasi panjang dan pola digit ISBN-10 (9 digit + digit/X) atau ISBN-13 (13 digit angka).
abstract final class IsbnNormalizer {
  static final RegExp _nonAlphanumericRegex = RegExp(r'[^0-9a-zA-Z]');
  static final RegExp _isbn10Regex = RegExp(r'^\d{9}[\dX]$');
  static final RegExp _isbn13Regex = RegExp(r'^\d{13}$');

  /// Menormalisasi string ISBN mentah (menghapus tanda hubung/spasi & kapitalisasi `X`).
  static String normalize(String? raw) {
    if (raw == null || raw.isEmpty) {
      return '';
    }
    return raw.replaceAll(_nonAlphanumericRegex, '').toUpperCase();
  }

  /// Memeriksa apakah string ISBN (mentah maupun sudah normal) merupakan ISBN-10 atau ISBN-13 yang sah.
  static bool isValid(String? raw) {
    final normalized = normalize(raw);
    if (normalized.isEmpty) {
      return false;
    }
    return _isbn10Regex.hasMatch(normalized) ||
        _isbn13Regex.hasMatch(normalized);
  }

  /// Membandingkan apakah dua string ISBN merujuk pada nomor ISBN non-kosong yang sama (`BR-01`).
  /// Mengembalikan `false` jika salah satu ISBN kosong.
  static bool isSameIsbn(String? first, String? second) {
    final normA = normalize(first);
    final normB = normalize(second);
    if (normA.isEmpty || normB.isEmpty) {
      return false;
    }
    return normA == normB;
  }
}
