import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/isbn_normalizer.dart';
import 'reading_status.dart';

/// Entitas utama `Book` (pure Dart) sesuai skema sheet `Books` pada `@docs/DATA_MODEL.md`.
class Book {
  Book({
    required this.id,
    required this.title,
    String isbn = '',
    this.authors = '',
    this.publisher = '',
    this.publishedYear = '',
    this.coverUrl = '',
    this.readingStatus = ReadingStatus.unread,
    this.isBorrowed = false,
    String borrowerName = '',
    String borrowedAt = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  })  : isbn = IsbnNormalizer.normalize(isbn),
        borrowerName = isBorrowed ? borrowerName.trim() : '',
        borrowedAt = isBorrowed ? borrowedAt.trim() : '';

  final String id;
  final String isbn;
  final String title;
  final String authors;
  final String publisher;
  final String publishedYear;
  final String coverUrl;
  final ReadingStatus readingStatus;
  final bool isBorrowed;
  final String borrowerName;
  final String borrowedAt;
  final String notes;
  final String createdAt;
  final String updatedAt;

  Book copyWith({
    String? id,
    String? isbn,
    String? title,
    String? authors,
    String? publisher,
    String? publishedYear,
    String? coverUrl,
    ReadingStatus? readingStatus,
    bool? isBorrowed,
    String? borrowerName,
    String? borrowedAt,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    final nextBorrowed = isBorrowed ?? this.isBorrowed;
    return Book(
      id: id ?? this.id,
      isbn: isbn != null ? IsbnNormalizer.normalize(isbn) : this.isbn,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      publisher: publisher ?? this.publisher,
      publishedYear: publishedYear ?? this.publishedYear,
      coverUrl: coverUrl ?? this.coverUrl,
      readingStatus: readingStatus ?? this.readingStatus,
      isBorrowed: nextBorrowed,
      borrowerName: nextBorrowed ? (borrowerName ?? this.borrowerName) : '',
      borrowedAt: nextBorrowed ? (borrowedAt ?? this.borrowedAt) : '',
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Mencatat buku sedang dipinjam teman (`F-09`) tanpa mengubah [readingStatus].
  /// Memvalidasi `borrowerName` dan `borrowedAt` wajib terisi (`BR-03`).
  Book markBorrowed({
    required String borrowerName,
    required String borrowedAt,
    String? updatedAt,
  }) {
    final cleanName = borrowerName.trim();
    final cleanDate = borrowedAt.trim();
    if (cleanName.isEmpty) {
      throw const ValidationException('Nama peminjam wajib diisi.');
    }
    if (cleanDate.isEmpty) {
      throw const ValidationException('Tanggal pinjam wajib diisi.');
    }

    return copyWith(
      isBorrowed: true,
      borrowerName: cleanName,
      borrowedAt: cleanDate,
      updatedAt: updatedAt ?? DateTime.now().toUtc().toIso8601String(),
    );
  }

  /// Menandai buku sudah dikembalikan (`F-09`, `BR-03`):
  /// Mengubah [isBorrowed] menjadi `false` dan mengosongkan [borrowerName] serta [borrowedAt] (`""`)
  /// tanpa mengubah [readingStatus].
  Book markReturned({String? updatedAt}) {
    return copyWith(
      isBorrowed: false,
      borrowerName: '',
      borrowedAt: '',
      updatedAt: updatedAt ?? DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book &&
        other.id == id &&
        other.isbn == isbn &&
        other.title == title &&
        other.authors == authors &&
        other.publisher == publisher &&
        other.publishedYear == publishedYear &&
        other.coverUrl == coverUrl &&
        other.readingStatus == readingStatus &&
        other.isBorrowed == isBorrowed &&
        other.borrowerName == borrowerName &&
        other.borrowedAt == borrowedAt &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        isbn,
        title,
        authors,
        publisher,
        publishedYear,
        coverUrl,
        readingStatus,
        isBorrowed,
        borrowerName,
        borrowedAt,
        notes,
        createdAt,
        updatedAt,
      );
}

/// Metadata hasil lookup ISBN dari Google Books API (`F-03`, `@docs/INTEGRATIONS.md`).
class BookMetadata {
  BookMetadata({
    required String isbn,
    required this.title,
    this.authors = '',
    this.publisher = '',
    this.publishedYear = '',
    this.coverUrl = '',
  }) : isbn = IsbnNormalizer.normalize(isbn);

  final String isbn;
  final String title;
  final String authors;
  final String publisher;
  final String publishedYear;
  final String coverUrl;
}
