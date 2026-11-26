import '../entities/book.dart';

/// Kontrak interface repository koleksi buku (`@docs/ARCHITECTURE.md`).
/// Pure Dart tanpa ketergantungan pada Flutter UI maupun Dio.
abstract class BookRepository {
  /// Mengambil seluruh daftar buku dari sheet `Books` via GAS App (`GET ?action=list`).
  Future<List<Book>> getBooks();

  /// Menambahkan buku baru ke sheet `Books` via GAS App (`POST action: "create"`).
  Future<Book> createBook(Book book);

  /// Memperbarui metadata, status baca, atau status peminjaman buku (`POST action: "update"`).
  Future<Book> updateBook(Book book);

  /// Menghapus baris buku secara permanen berdasarkan [id] (`POST action: "delete"`).
  Future<void> deleteBook(String id);

  /// Mencari metadata buku dari Google Books API berdasarkan nomor [isbn] (`F-03`).
  /// Mengembalikan `null` jika ISBN tidak ditemukan (`totalItems == 0`).
  Future<BookMetadata?> lookupBookByIsbn(String isbn);
}
