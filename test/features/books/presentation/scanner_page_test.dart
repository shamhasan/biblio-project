import 'package:book_inventory_apps/core/router/app_router.dart';
import 'package:book_inventory_apps/core/theme/app_theme.dart';
import 'package:book_inventory_apps/features/books/domain/entities/book.dart';
import 'package:book_inventory_apps/features/books/domain/entities/book_form_args.dart';
import 'package:book_inventory_apps/features/books/domain/entities/reading_status.dart';
import 'package:book_inventory_apps/features/books/domain/repositories/book_repository.dart';
import 'package:book_inventory_apps/features/books/presentation/pages/scanner_page.dart';
import 'package:book_inventory_apps/features/books/presentation/providers/books_provider.dart';
import 'package:book_inventory_apps/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockBookRepository extends Mock implements BookRepository {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final existingCollection = <Book>[
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
  ];

  Future<Widget> buildScannerTestHarness({
    required MockBookRepository mockRepo,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    final router = GoRouter(
      initialLocation: AppRoutes.scanner,
      routes: <RouteBase>[
        ShellRoute(
          builder: (context, state, child) => AppNavigationShell(
            location: state.uri.path,
            child: child,
          ),
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.scanner,
              builder: (context, state) => const ScannerPage(
                enableCamera: false,
              ),
            ),
            GoRoute(
              path: AppRoutes.bookForm,
              builder: (context, state) {
                final args = state.extra as BookFormArgs?;
                return Scaffold(
                  body: Column(
                    children: <Widget>[
                      const Text('BookFormDestination'),
                      if (args?.prefillMetadata != null)
                        Text('PrefillTitle:${args!.prefillMetadata!.title}'),
                      if (args != null)
                        Text('FormInitialIsbn:${args.initialIsbn}'),
                    ],
                  ),
                );
              },
            ),
            GoRoute(
              path: AppRoutes.bookDetailPattern,
              builder: (context, state) {
                final id = state.pathParameters['id'];
                return Scaffold(
                  body: Text('BookDetailDestination:$id'),
                );
              },
            ),
          ],
        ),
      ],
    );

    return ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        bookRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          // Pastikan booksProvider dimuat agar daftar koleksi siap saat cek duplikat
          ref.watch(booksProvider);
          return MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
          );
        },
      ),
    );
  }

  group('ScannerPage & IsbnLookupNotifier (T-007: F-02, F-03, F-04, F-05)', () {
    testWidgets(
        'Scenario 1 (New ISBN Found): Looks up Google Books API and navigates to /book/form with prefill metadata',
        (tester) async {
      final mockRepo = MockBookRepository();
      when(() => mockRepo.getBooks())
          .thenAnswer((_) async => existingCollection);
      when(() => mockRepo.lookupBookByIsbn('9786020633176')).thenAnswer(
        (_) async => BookMetadata(
          isbn: '9786020633176',
          title: 'Atomic Habits',
          authors: 'James Clear',
          publisher: 'Gramedia',
          publishedYear: '2019',
          coverUrl: 'https://books.google.com/books/content?id=123',
        ),
      );

      final app = await buildScannerTestHarness(mockRepo: mockRepo);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Masukkan ISBN baru yang belum ada di koleksi
      await tester.enterText(
        find.byKey(const Key('scanner_isbn_input')),
        '978-602-063-317-6',
      );
      final lookupBtn = find.byKey(const Key('lookup_isbn_button'));
      await tester.ensureVisible(lookupBtn);
      await tester.tap(lookupBtn);
      await tester.pumpAndSettle();

      verify(() => mockRepo.lookupBookByIsbn('9786020633176')).called(1);
      expect(find.text('BookFormDestination'), findsOneWidget);
      expect(find.text('PrefillTitle:Atomic Habits'), findsOneWidget);
      expect(find.text('FormInitialIsbn:9786020633176'), findsOneWidget);
    });

    testWidgets(
        'Scenario 2 (Duplicate ISBN Blocked - BR-01, F-04): Blocks lookup, shows duplicate banner, and navigates to existing book detail',
        (tester) async {
      final mockRepo = MockBookRepository();
      when(() => mockRepo.getBooks())
          .thenAnswer((_) async => existingCollection);

      final app = await buildScannerTestHarness(mockRepo: mockRepo);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Pindai/masukkan ISBN dengan tanda hubung yang sebenarnya sudah ada di koleksi (9789792248616)
      await tester.enterText(
        find.byKey(const Key('scanner_isbn_input')),
        '978-979-224-861-6',
      );
      final lookupBtn = find.byKey(const Key('lookup_isbn_button'));
      await tester.ensureVisible(lookupBtn);
      await tester.tap(lookupBtn);
      await tester.pumpAndSettle();

      // Google Books API TIDAK boleh dipanggil karena sudah terblokir oleh cek duplikat lokal
      verifyNever(() => mockRepo.lookupBookByIsbn(any()));

      // Banner peringatan duplikat wajib tampil dengan bahasa ramah pembaca
      expect(find.byKey(const Key('duplicate_isbn_alert')), findsOneWidget);
      expect(
        find.text('Buku ini sudah ada di rakmu'),
        findsOneWidget,
      );

      // Ketuk tombol "Lihat Detail Buku"
      final viewDetailBtn = find.byKey(
        const Key('view_duplicate_detail_button'),
      );
      await tester.ensureVisible(viewDetailBtn);
      await tester.tap(viewDetailBtn);
      await tester.pumpAndSettle();

      expect(find.text('BookDetailDestination:bk-1'), findsOneWidget);
    });

    testWidgets(
        'Scenario 3 (ISBN Not Found in Google Books - F-05): Shows not-found banner and carries ISBN to manual form',
        (tester) async {
      final mockRepo = MockBookRepository();
      when(() => mockRepo.getBooks())
          .thenAnswer((_) async => existingCollection);
      when(() => mockRepo.lookupBookByIsbn('9786020001112'))
          .thenAnswer((_) async => null);

      final app = await buildScannerTestHarness(mockRepo: mockRepo);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('scanner_isbn_input')),
        '978-602-000-111-2',
      );
      final lookupBtn = find.byKey(const Key('lookup_isbn_button'));
      await tester.ensureVisible(lookupBtn);
      await tester.tap(lookupBtn);
      await tester.pumpAndSettle();

      verify(() => mockRepo.lookupBookByIsbn('9786020001112')).called(1);

      // Banner "Detail buku belum ditemukan secara otomatis" tampil
      expect(find.byKey(const Key('not_found_isbn_alert')), findsOneWidget);
      expect(
        find.text('Detail buku belum ditemukan secara otomatis'),
        findsOneWidget,
      );

      // Ketuk "Isi Manual Sekarang" -> membawa ISBN 9786020001112 ke /book/form
      final fallbackBtn = find.byKey(const Key('fallback_manual_form_button'));
      await tester.ensureVisible(fallbackBtn);
      await tester.tap(fallbackBtn);
      await tester.pumpAndSettle();

      expect(find.text('BookFormDestination'), findsOneWidget);
      expect(find.text('FormInitialIsbn:9786020001112'), findsOneWidget);
    });
  });
}
