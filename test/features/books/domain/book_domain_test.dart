import 'package:book_inventory_apps/core/error/app_exception.dart';
import 'package:book_inventory_apps/features/books/domain/entities/book.dart';
import 'package:book_inventory_apps/features/books/domain/entities/reading_status.dart';
import 'package:book_inventory_apps/features/books/domain/usecases/check_duplicate_isbn.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sampleBook = Book(
    id: 'bk-1',
    isbn: '978-979-224-861-6',
    title: 'Negeri 5 Menara',
    authors: 'Ahmad Fuadi',
    publisher: 'Gramedia',
    publishedYear: '2009',
    coverUrl: '',
    readingStatus: ReadingStatus.reading,
    isBorrowed: false,
    createdAt: '2026-11-25T08:00:00Z',
    updatedAt: '2026-11-25T08:00:00Z',
  );

  group('ReadingStatus', () {
    test('Parses API values accurately and defaults to unread', () {
      expect(ReadingStatus.fromApiValue('unread'), ReadingStatus.unread);
      expect(ReadingStatus.fromApiValue('reading'), ReadingStatus.reading);
      expect(ReadingStatus.fromApiValue('FINISHED'), ReadingStatus.finished);
      expect(ReadingStatus.fromApiValue('unknown'), ReadingStatus.unread);
      expect(ReadingStatus.fromApiValue(null), ReadingStatus.unread);
    });
  });

  group('Book Entity & BR-03 (Borrow / Return separation)', () {
    test('Normalizes ISBN on construction and enforces empty borrower when not borrowed', () {
      final book = Book(
        id: 'bk-2',
        isbn: '978-602-063-317-6',
        title: 'Atomic Habits',
        isBorrowed: false,
        borrowerName: 'Harus Dikosongkan',
        borrowedAt: '2026-11-25',
        createdAt: '2026-11-25T08:00:00Z',
        updatedAt: '2026-11-25T08:00:00Z',
      );

      expect(book.isbn, '9786020633176');
      expect(book.borrowerName, '');
      expect(book.borrowedAt, '');
    });

    test('markBorrowed sets borrower details without changing readingStatus, markReturned clears them (BR-03)', () {
      final borrowed = sampleBook.markBorrowed(
        borrowerName: 'Raka Pratama',
        borrowedAt: '2026-11-25',
        updatedAt: '2026-11-25T10:00:00Z',
      );

      expect(borrowed.isBorrowed, isTrue);
      expect(borrowed.borrowerName, 'Raka Pratama');
      expect(borrowed.borrowedAt, '2026-11-25');
      expect(borrowed.readingStatus, ReadingStatus.reading);

      final returned = borrowed.markReturned(
        updatedAt: '2026-11-26T09:00:00Z',
      );

      expect(returned.isBorrowed, isFalse);
      expect(returned.borrowerName, '');
      expect(returned.borrowedAt, '');
      expect(returned.readingStatus, ReadingStatus.reading);
    });

    test('markBorrowed throws ValidationException if borrowerName is empty', () {
      expect(
        () => sampleBook.markBorrowed(borrowerName: '   ', borrowedAt: '2026-11-25'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('CheckDuplicateIsbn UseCase (BR-01, F-04)', () {
    const checkDuplicate = CheckDuplicateIsbn();
    final collection = <Book>[
      sampleBook,
      Book(
        id: 'bk-no-isbn',
        isbn: '',
        title: 'Buku Zine Indie',
        createdAt: '2026-11-25T08:00:00Z',
        updatedAt: '2026-11-25T08:00:00Z',
      ),
    ];

    test('Finds existing book when scanned ISBN has hyphens or spaces', () {
      final duplicate = checkDuplicate(
        rawIsbn: '978-979-224-861-6',
        existingBooks: collection,
      );

      expect(duplicate, isNotNull);
      expect(duplicate?.id, 'bk-1');
    });

    test('Returns null when ISBN is new or empty', () {
      expect(
        checkDuplicate(rawIsbn: '9786020633176', existingBooks: collection),
        isNull,
      );
      expect(
        checkDuplicate(rawIsbn: '   ', existingBooks: collection),
        isNull,
      );
    });

    test('Respects excludeBookId when editing existing book', () {
      expect(
        checkDuplicate(
          rawIsbn: '9789792248616',
          existingBooks: collection,
          excludeBookId: 'bk-1',
        ),
        isNull,
      );
    });
  });
}
