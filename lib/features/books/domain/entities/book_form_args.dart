import '../../../../core/utils/isbn_normalizer.dart';
import 'book.dart';

/// Kontrak argumen navigasi menuju `BookFormPage` (`/book/form`)
/// sesuai `@docs/ARCHITECTURE.md` (pure Dart).
class BookFormArgs {
  /// Membuka formulir tambah buku manual (opsional membawa [initialIsbn] hasil scan yang tak ditemukan).
  BookFormArgs.manual({String initialIsbn = ''})
      : existingBook = null,
        prefillMetadata = null,
        initialIsbn = IsbnNormalizer.normalize(initialIsbn);

  /// Membuka formulir tambah buku baru dengan hasil *autofill* dari Google Books API (`F-03`).
  BookFormArgs.prefill(BookMetadata metadata)
      : existingBook = null,
        prefillMetadata = metadata,
        initialIsbn = metadata.isbn;

  /// Membuka formulir dalam mode sunting metadata buku yang sudah ada (`F-08`).
  BookFormArgs.edit(Book book)
      : existingBook = book,
        prefillMetadata = null,
        initialIsbn = book.isbn;

  final Book? existingBook;
  final BookMetadata? prefillMetadata;
  final String initialIsbn;

  bool get isEditMode => existingBook != null;
  bool get isPrefillMode => prefillMetadata != null;
}
