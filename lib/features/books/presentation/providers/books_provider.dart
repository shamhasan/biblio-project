import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/isbn_normalizer.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/reading_status.dart';
import '../../domain/repositories/book_repository.dart';

/// Provider untuk kontrak interface [BookRepository].
/// Di-override pada `ProviderScope` di `main.dart` (dan di pengujian)
/// agar layer `presentation` tidak pernah mengimpor layer `data` atau `dio`.
final bookRepositoryProvider = Provider<BookRepository>((ref) {
  throw UnimplementedError(
    'bookRepositoryProvider wajib di-override di ProviderScope (main.dart).',
  );
});

/// Pilihan filter chip pada `HomePage` (`F-12`).
enum BookCollectionFilter {
  all('all', 'Semua'),
  reading('reading', 'Sedang Dibaca'),
  finished('finished', 'Selesai'),
  unread('unread', 'Belum Dibaca'),
  borrowed('borrowed', 'Dipinjam Teman');

  const BookCollectionFilter(this.key, this.label);

  final String key;
  final String label;
}

/// Ringkasan angka statistik koleksi buku (`F-01`).
@immutable
class BookCollectionStats {
  const BookCollectionStats({
    this.totalBooks = 0,
    this.readingBooks = 0,
    this.borrowedBooks = 0,
  });

  final int totalBooks;
  final int readingBooks;
  final int borrowedBooks;
}

/// Notifier utama yang memegang daftar koleksi buku dari GAS App di memori (`@docs/ARCHITECTURE.md`).
class BooksNotifier extends AsyncNotifier<List<Book>> {
  @override
  Future<List<Book>> build() async {
    // Otomatis memuat ulang daftar buku bila pengguna mengubah URL GAS di Setelan
    final gasUrl = ref.watch(
      settingsProvider.select((s) => s.gasWebAppUrl.trim()),
    );
    if (gasUrl.isEmpty) {
      throw const EmptyGasUrlException();
    }

    final repository = ref.watch(bookRepositoryProvider);
    return repository.getBooks();
  }

  /// Memuat ulang koleksi buku dari GAS App.
  Future<void> refresh() async {
    state = const AsyncLoading<List<Book>>();
    state = await AsyncValue.guard(() async {
      final gasUrl = ref.read(settingsProvider).gasWebAppUrl.trim();
      if (gasUrl.isEmpty) {
        throw const EmptyGasUrlException();
      }
      return ref.read(bookRepositoryProvider).getBooks();
    });
  }

  /// Menambahkan buku baru ke GAS App lalu memperbarui state di memori.
  Future<Book> addBook(Book book) async {
    final repository = ref.read(bookRepositoryProvider);
    final created = await repository.createBook(book);
    final currentList = state.valueOrNull ?? const <Book>[];
    state = AsyncData<List<Book>>(<Book>[created, ...currentList]);
    return created;
  }

  /// Memperbarui metadata atau status baca buku di GAS App lalu menyegarkan state lokal.
  Future<Book> editBook(Book book) async {
    final repository = ref.read(bookRepositoryProvider);
    final updated = await repository.updateBook(book);
    final currentList = state.valueOrNull ?? const <Book>[];
    state = AsyncData<List<Book>>(
      currentList.map((item) => item.id == updated.id ? updated : item).toList(),
    );
    return updated;
  }

  /// Mencatat peminjaman buku kepada teman (`F-09`) tanpa mengubah `readingStatus`.
  Future<Book> borrowBook({
    required String bookId,
    required String borrowerName,
    required String borrowedAt,
  }) async {
    final currentList = state.valueOrNull ?? const <Book>[];
    final target = currentList.where((b) => b.id == bookId).firstOrNull;
    if (target == null) {
      throw const NotFoundException('Buku tidak ditemukan di memori.');
    }

    final borrowedBook = target.markBorrowed(
      borrowerName: borrowerName,
      borrowedAt: borrowedAt,
    );
    return editBook(borrowedBook);
  }

  /// Menandai buku sudah dikembalikan (`F-09`, `BR-03`) dengan mengosongkan nama & tanggal pinjam.
  Future<Book> returnBook(String bookId) async {
    final currentList = state.valueOrNull ?? const <Book>[];
    final target = currentList.where((b) => b.id == bookId).firstOrNull;
    if (target == null) {
      throw const NotFoundException('Buku tidak ditemukan di memori.');
    }

    final returnedBook = target.markReturned();
    return editBook(returnedBook);
  }

  /// Menghapus baris buku secara permanen dari GAS App dan state lokal (`F-10`).
  Future<void> removeBook(String bookId) async {
    final repository = ref.read(bookRepositoryProvider);
    await repository.deleteBook(bookId);
    final currentList = state.valueOrNull ?? const <Book>[];
    state = AsyncData<List<Book>>(
      currentList.where((item) => item.id != bookId).toList(),
    );
  }
}

final booksProvider =
    AsyncNotifierProvider<BooksNotifier, List<Book>>(BooksNotifier.new);

/// Notifier kata kunci pencarian teks (`title`, `authors`, `isbn`).
class BookSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final bookSearchQueryProvider =
    NotifierProvider<BookSearchQueryNotifier, String>(
  BookSearchQueryNotifier.new,
);

/// Notifier filter chip koleksi aktif.
class BookFilterNotifier extends Notifier<BookCollectionFilter> {
  @override
  BookCollectionFilter build() => BookCollectionFilter.all;

  void setFilter(BookCollectionFilter filter) {
    state = filter;
  }
}

final bookFilterProvider =
    NotifierProvider<BookFilterNotifier, BookCollectionFilter>(
  BookFilterNotifier.new,
);

/// Computed provider untuk statistik ringkasan koleksi (`Total Buku`, `Dibaca`, `Dipinjam`).
final bookCollectionStatsProvider = Provider<BookCollectionStats>((ref) {
  final books = ref.watch(booksProvider).valueOrNull ?? const <Book>[];
  final readingCount = books
      .where((b) => b.readingStatus == ReadingStatus.reading)
      .length;
  final borrowedCount = books.where((b) => b.isBorrowed).length;

  return BookCollectionStats(
    totalBooks: books.length,
    readingBooks: readingCount,
    borrowedBooks: borrowedCount,
  );
});

/// Computed provider yang menyaring `booksProvider` berdasarkan kata kunci pencarian
/// dan filter chip secara instan di memori (`F-12`).
final filteredBooksProvider = Provider<List<Book>>((ref) {
  final books = ref.watch(booksProvider).valueOrNull ?? const <Book>[];
  final rawQuery = ref.watch(bookSearchQueryProvider).trim().toLowerCase();
  final normalizedIsbnQuery = IsbnNormalizer.normalize(rawQuery).toLowerCase();
  final activeFilter = ref.watch(bookFilterProvider);

  return books.where((book) {
    final matchesFilter = switch (activeFilter) {
      BookCollectionFilter.all => true,
      BookCollectionFilter.reading =>
        book.readingStatus == ReadingStatus.reading,
      BookCollectionFilter.finished =>
        book.readingStatus == ReadingStatus.finished,
      BookCollectionFilter.unread =>
        book.readingStatus == ReadingStatus.unread,
      BookCollectionFilter.borrowed => book.isBorrowed,
    };

    if (!matchesFilter) {
      return false;
    }

    if (rawQuery.isEmpty) {
      return true;
    }

    final titleMatch = book.title.toLowerCase().contains(rawQuery);
    final authorMatch = book.authors.toLowerCase().contains(rawQuery);
    final rawIsbnMatch = book.isbn.toLowerCase().contains(rawQuery);
    final normIsbnMatch = normalizedIsbnQuery.isNotEmpty &&
        book.isbn.toLowerCase().contains(normalizedIsbnQuery);

    return titleMatch || authorMatch || rawIsbnMatch || normIsbnMatch;
  }).toList();
});
