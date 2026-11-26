import '../../../../core/utils/isbn_normalizer.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/reading_status.dart';

/// DTO Model untuk pemetaan JSON `snake_case` antara GAS App (`Books` sheet)
/// dan entitas domain [Book] sesuai `@docs/DATA_MODEL.md` & `@docs/API_SPEC.md`.
class BookModel {
  const BookModel({
    required this.id,
    required this.isbn,
    required this.title,
    required this.authors,
    required this.publisher,
    required this.publishedYear,
    required this.coverUrl,
    required this.readingStatus,
    required this.isBorrowed,
    required this.borrowerName,
    required this.borrowedAt,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookModel.fromEntity(Book book) {
    final normalizedIsbn = IsbnNormalizer.normalize(book.isbn);
    return BookModel(
      id: book.id.trim(),
      isbn: normalizedIsbn,
      title: book.title.trim(),
      authors: book.authors.trim(),
      publisher: book.publisher.trim(),
      publishedYear: book.publishedYear.trim(),
      coverUrl: book.coverUrl.trim(),
      readingStatus: book.readingStatus.apiValue,
      isBorrowed: book.isBorrowed,
      borrowerName: book.isBorrowed ? book.borrowerName.trim() : '',
      borrowedAt: book.isBorrowed ? book.borrowedAt.trim() : '',
      notes: book.notes.trim(),
      createdAt: book.createdAt,
      updatedAt: book.updatedAt,
    );
  }

  factory BookModel.fromJson(Map<String, dynamic> json) {
    final rawBorrowed = json['is_borrowed'];
    final isBorrowed = switch (rawBorrowed) {
      final bool b => b,
      final String s => s.trim().toLowerCase() == 'true',
      final num n => n != 0,
      _ => false,
    };

    return BookModel(
      id: _asString(json['id']),
      isbn: IsbnNormalizer.normalize(_asString(json['isbn'])),
      title: _asString(json['title']),
      authors: _asString(json['authors']),
      publisher: _asString(json['publisher']),
      publishedYear: _asString(json['published_year']),
      coverUrl: _asString(json['cover_url']),
      readingStatus: ReadingStatus.fromApiValue(
        _asString(json['reading_status']),
      ).apiValue,
      isBorrowed: isBorrowed,
      borrowerName: isBorrowed ? _asString(json['borrower_name']) : '',
      borrowedAt: isBorrowed ? _asString(json['borrowed_at']) : '',
      notes: _asString(json['notes']),
      createdAt: _asString(json['created_at']),
      updatedAt: _asString(json['updated_at']),
    );
  }

  final String id;
  final String isbn;
  final String title;
  final String authors;
  final String publisher;
  final String publishedYear;
  final String coverUrl;
  final String readingStatus;
  final bool isBorrowed;
  final String borrowerName;
  final String borrowedAt;
  final String notes;
  final String createdAt;
  final String updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'isbn': isbn,
      'title': title,
      'authors': authors,
      'publisher': publisher,
      'published_year': publishedYear,
      'cover_url': coverUrl,
      'reading_status': readingStatus,
      'is_borrowed': isBorrowed,
      'borrower_name': isBorrowed ? borrowerName : '',
      'borrowed_at': isBorrowed ? borrowedAt : '',
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Book toEntity() {
    return Book(
      id: id,
      isbn: isbn,
      title: title,
      authors: authors,
      publisher: publisher,
      publishedYear: publishedYear,
      coverUrl: coverUrl,
      readingStatus: ReadingStatus.fromApiValue(readingStatus),
      isBorrowed: isBorrowed,
      borrowerName: isBorrowed ? borrowerName : '',
      borrowedAt: isBorrowed ? borrowedAt : '',
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static String _asString(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}
