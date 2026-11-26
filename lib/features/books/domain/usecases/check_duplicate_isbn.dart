import '../../../../core/utils/isbn_normalizer.dart';
import '../entities/book.dart';

/// Use case untuk memeriksa apakah nomor ISBN sudah terdaftar di dalam koleksi (`BR-01`, `F-04`).
/// - Menormalisasi `rawIsbn` terlebih dahulu (menghapus `-` dan spasi, kapitalisasi `X`).
/// - Jika `rawIsbn` kosong setelah dinormalisasi, mengembalikan `null` (buku tanpa ISBN tidak diblokir).
/// - Jika ditemukan buku dengan ISBN ternormalisasi yang sama (dan `id != excludeBookId`),
///   mengembalikan entitas [Book] yang sudah ada tersebut.
class CheckDuplicateIsbn {
  const CheckDuplicateIsbn();

  Book? call({
    required String? rawIsbn,
    required Iterable<Book> existingBooks,
    String? excludeBookId,
  }) {
    final normalizedTarget = IsbnNormalizer.normalize(rawIsbn);
    if (normalizedTarget.isEmpty) {
      return null;
    }

    for (final book in existingBooks) {
      if (excludeBookId != null && book.id == excludeBookId) {
        continue;
      }
      if (IsbnNormalizer.isSameIsbn(book.isbn, normalizedTarget)) {
        return book;
      }
    }
    return null;
  }
}
