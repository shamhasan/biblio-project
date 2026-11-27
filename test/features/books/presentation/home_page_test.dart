import 'package:book_inventory_apps/app.dart';
import 'package:book_inventory_apps/core/config/app_preferences.dart';
import 'package:book_inventory_apps/core/error/app_exception.dart';
import 'package:book_inventory_apps/core/widgets/book_cover_view.dart';
import 'package:book_inventory_apps/core/widgets/floating_bottom_nav.dart';
import 'package:book_inventory_apps/core/widgets/generated_book_cover.dart';
import 'package:book_inventory_apps/features/books/domain/entities/book.dart';
import 'package:book_inventory_apps/features/books/domain/entities/reading_status.dart';
import 'package:book_inventory_apps/features/books/domain/repositories/book_repository.dart';
import 'package:book_inventory_apps/features/books/presentation/providers/books_provider.dart';
import 'package:book_inventory_apps/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockBookRepository extends Mock implements BookRepository {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final sampleBooks = <Book>[
    Book(
      id: 'bk-1',
      isbn: '9789792248616',
      title: 'Negeri 5 Menara',
      authors: 'Ahmad Fuadi',
      publisher: 'Gramedia',
      publishedYear: '2009',
      coverUrl: '',
      readingStatus: ReadingStatus.reading,
      isBorrowed: false,
      createdAt: '2026-11-25T08:00:00Z',
      updatedAt: '2026-11-25T08:00:00Z',
    ),
    Book(
      id: 'bk-2',
      isbn: '9786020633176',
      title: 'Atomic Habits',
      authors: 'James Clear',
      publisher: 'Gramedia',
      publishedYear: '2019',
      coverUrl: '',
      readingStatus: ReadingStatus.finished,
      isBorrowed: true,
      borrowerName: 'Raka',
      borrowedAt: '2026-11-18',
      createdAt: '2026-11-25T08:00:00Z',
      updatedAt: '2026-11-25T08:00:00Z',
    ),
    Book(
      id: 'bk-3',
      isbn: '9786024246945',
      title: 'Laut Bercerita',
      authors: 'Leila S. Chudori',
      publisher: 'KPG',
      publishedYear: '2017',
      coverUrl: '',
      readingStatus: ReadingStatus.unread,
      isBorrowed: false,
      createdAt: '2026-11-25T08:00:00Z',
      updatedAt: '2026-11-25T08:00:00Z',
    ),
  ];

  Future<SharedPreferences> createPrefsWithGasUrl() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppPreferences.keyGasWebAppUrl:
          'https://script.google.com/macros/s/test-deploy/exec',
    });
    return SharedPreferences.getInstance();
  }

  group('HomePage & BookshelfPage (T-006 & D-013: F-01, F-06, F-11, F-12)', () {
    testWidgets(
        'Renders typewriter greeting header on HomePage, summary stats, BookCoverView fallback, and 4-tab FloatingBottomNav',
        (tester) async {
      final prefs = await createPrefsWithGasUrl();
      final mockRepo = MockBookRepository();
      when(() => mockRepo.getBooks()).thenAnswer((_) async => sampleBooks);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            bookRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const BookInventoryApp(),
        ),
      );

      // Pada frame awal sebelum animasi menulis selesai, teks sapaan sudah mulai diketik
      await tester.pump(const Duration(milliseconds: 100));
      final greetingText = tester
          .widget<Text>(find.byKey(const Key('dynamic_greeting_title')));
      expect(greetingText.data?.isNotEmpty, isTrue);

      // Lewati delay 1000ms dan durasi animasi 1800ms
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 1800));
      await tester.pumpAndSettle();

      // Setelah animasi selesai, teks sapaan lengkap ("Selamat ...") tampil penuh
      final finalGreetingText = tester
          .widget<Text>(find.byKey(const Key('dynamic_greeting_title')));
      expect(finalGreetingText.data, startsWith('Selamat '));

      // Pastikan FloatingBottomNav 4 tab berada di top-level Stack ShellRoute
      expect(find.byType(FloatingBottomNav), findsOneWidget);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Rak Buku'), findsOneWidget);
      expect(find.text('Pindai'), findsOneWidget);
      expect(find.text('Setelan'), findsOneWidget);

      // Statistik ringkasan & daftar buku terbaru
      expect(find.text('Ringkasan Rak Buku'), findsOneWidget);
      expect(find.text('Google Sheets'), findsNothing);
      expect(find.text('Negeri 5 Menara'), findsWidgets);
      expect(find.text('Atomic Habits'), findsWidgets);
      expect(find.text('Laut Bercerita'), findsWidgets);
      expect(find.text('Dipinjam: Raka'), findsOneWidget);

      expect(find.byType(BookCoverView), findsNWidgets(3));
      expect(find.byType(GeneratedBookCover), findsNWidgets(3));
    });

    testWidgets(
        'Navigates to dedicated BookshelfPage (/books) and filters books by search query and filter chips',
        (tester) async {
      final prefs = await createPrefsWithGasUrl();
      final mockRepo = MockBookRepository();
      when(() => mockRepo.getBooks()).thenAnswer((_) async => sampleBooks);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            bookRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const BookInventoryApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Pindah ke tab "Rak Buku" (/books) lewat FloatingBottomNav
      await tester.tap(find.text('Rak Buku'));
      await tester.pumpAndSettle();

      expect(find.text('Rak Bukumu'), findsOneWidget);
      expect(find.text('Semua (3)'), findsOneWidget);

      // 1. Cari berdasarkan ISBN berformat tanda hubung
      await tester.enterText(
        find.byKey(const Key('collection_search_input')),
        '978-602-063-317-6',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('book_card_bk-2')), findsOneWidget);
      expect(find.byKey(const Key('book_card_bk-1')), findsNothing);
      expect(find.byKey(const Key('book_card_bk-3')), findsNothing);

      // Hapus pencarian
      await tester.tap(find.byKey(const Key('clear_search_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('book_card_bk-1')), findsOneWidget);
      expect(find.byKey(const Key('book_card_bk-2')), findsOneWidget);
      expect(find.byKey(const Key('book_card_bk-3')), findsOneWidget);

      // 2. Filter chip: "Dipinjam Teman"
      final borrowedChip = find.byKey(const Key('filter_chip_borrowed'));
      await tester.ensureVisible(borrowedChip);
      await tester.tap(borrowedChip);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('book_card_bk-2')), findsOneWidget);
      expect(find.byKey(const Key('book_card_bk-1')), findsNothing);
      expect(find.byKey(const Key('book_card_bk-3')), findsNothing);

      // 3. Filter chip: "Sedang Dibaca"
      final readingChip = find.byKey(const Key('filter_chip_reading'));
      await tester.ensureVisible(readingChip);
      await tester.tap(readingChip);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('book_card_bk-1')), findsOneWidget);
      expect(find.byKey(const Key('book_card_bk-2')), findsNothing);
    });

    testWidgets(
        'Displays reader-friendly ErrorRetryView on timeout/network failure and reloads when "Coba Lagi" is tapped (F-11)',
        (tester) async {
      final prefs = await createPrefsWithGasUrl();
      final mockRepo = MockBookRepository();
      int callCount = 0;

      when(() => mockRepo.getBooks()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw const TimeoutException();
        }
        return sampleBooks;
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            bookRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const BookInventoryApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_error_retry_view')), findsOneWidget);
      expect(find.text('Belum dapat memuat koleksi buku'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      final retryButton = find.text('Coba Lagi');
      await tester.ensureVisible(retryButton);
      await tester.pumpAndSettle();
      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(callCount, 2);
      expect(find.byKey(const Key('home_error_retry_view')), findsNothing);
      expect(find.byKey(const Key('book_card_bk-1')), findsOneWidget);
    });
  });
}
