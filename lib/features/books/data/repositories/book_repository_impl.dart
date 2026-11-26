import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/isbn_normalizer.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/gas_book_datasource.dart';
import '../datasources/google_books_datasource.dart';
import '../models/book_model.dart';

/// Implementasi [BookRepository] yang mengoordinasikan [GasBookDataSource] dan [GoogleBooksDataSource]
/// serta menegakkan aturan bisnis domain (`BR-01`, `BR-02`, `BR-03`).
class BookRepositoryImpl implements BookRepository {
  const BookRepositoryImpl({
    required GasBookDataSource gasDataSource,
    required GoogleBooksDataSource googleBooksDataSource,
  })  : _gasDataSource = gasDataSource,
        _googleBooksDataSource = googleBooksDataSource;

  final GasBookDataSource _gasDataSource;
  final GoogleBooksDataSource _googleBooksDataSource;

  @override
  Future<List<Book>> getBooks() async {
    final models = await _gasDataSource.fetchBooks();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Book> createBook(Book book) async {
    final sanitized = _validateAndSanitize(book);
    final createdModel = await _gasDataSource.createBook(
      BookModel.fromEntity(sanitized),
    );
    return createdModel.toEntity();
  }

  @override
  Future<Book> updateBook(Book book) async {
    final sanitized = _validateAndSanitize(book);
    final updatedModel = await _gasDataSource.updateBook(
      BookModel.fromEntity(sanitized),
    );
    return updatedModel.toEntity();
  }

  @override
  Future<void> deleteBook(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      throw const ValidationException('ID buku tidak boleh kosong.');
    }
    await _gasDataSource.deleteBook(cleanId);
  }

  @override
  Future<BookMetadata?> lookupBookByIsbn(String isbn) {
    return _googleBooksDataSource.lookupByIsbn(isbn);
  }

  Book _validateAndSanitize(Book book) {
    final cleanTitle = book.title.trim();
    if (cleanTitle.isEmpty) {
      throw const ValidationException('Judul buku wajib diisi.');
    }

    if (book.isBorrowed) {
      if (book.borrowerName.trim().isEmpty) {
        throw const ValidationException('Nama peminjam wajib diisi.');
      }
      if (book.borrowedAt.trim().isEmpty) {
        throw const ValidationException('Tanggal pinjam wajib diisi.');
      }
    }

    return book.copyWith(
      isbn: IsbnNormalizer.normalize(book.isbn),
      title: cleanTitle,
      borrowerName: book.isBorrowed ? book.borrowerName.trim() : '',
      borrowedAt: book.isBorrowed ? book.borrowedAt.trim() : '',
    );
  }
}
