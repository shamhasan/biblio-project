import 'package:book_inventory_apps/app.dart';
import 'package:book_inventory_apps/core/router/app_router.dart';
import 'package:book_inventory_apps/core/theme/app_theme.dart';
import 'package:book_inventory_apps/core/widgets/floating_bottom_nav.dart';
import 'package:book_inventory_apps/core/widgets/generated_book_cover.dart';
import 'package:book_inventory_apps/features/books/domain/entities/book.dart';
import 'package:book_inventory_apps/features/books/domain/entities/book_form_args.dart';
import 'package:book_inventory_apps/features/books/domain/entities/reading_status.dart';
import 'package:book_inventory_apps/features/books/domain/repositories/book_repository.dart';
import 'package:book_inventory_apps/features/books/presentation/pages/book_form_page.dart';
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

class FakeBook extends Fake implements Book {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(FakeBook());
  });

  final existingBook = Book(
    id: 'bk-1',
    isbn: '9789792248616',
    title: 'Negeri 5 Menara',
    authors: 'Ahmad Fuadi',
    publisher: 'Gramedia',
    publishedYear: '2009',
    coverUrl: '',
    readingStatus: ReadingStatus.reading,
    isBorrowed: false,
    notes: 'Catatan lama',
    createdAt: '2026-11-25T08:00:00Z',
    updatedAt: '2026-11-25T08:00:00Z',
  );

  Future<Widget> buildFormTestApp({
    required MockBookRepository mockRepo,
    BookFormArgs? initialArgs,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    final router = GoRouter(
      initialLocation: AppRoutes.bookForm,
      initialExtra: initialArgs,
      routes: <RouteBase>[
        ShellRoute(
          builder: (context, state, child) => AppNavigationShell(
            location: state.uri.path,
            child: child,
          ),
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const Scaffold(
                body: Text('HomeDestination'),
              ),
            ),
            GoRoute(
              path: AppRoutes.bookForm,
              builder: (context, state) {
                final args = state.extra is BookFormArgs
                    ? state.extra as BookFormArgs
                    : initialArgs;
                return BookFormPage(args: args);
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
          ref.watch(booksProvider);
          return MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
          );
        },
      ),
    );
  }

  group('BookFormPage & Navigation Rules (T-008: F-03, F-05, F-06, F-08, D-012, D-013)', () {
    testWidgets(
        'Hides FloatingBottomNav and shows Back button on /book/form, rejects empty title (BR-02), renders live GeneratedBookCover, and auto-navigates to Home on create',
        (tester) async {
      final mockRepo = MockBookRepository();
      when(() => mockRepo.getBooks())
          .thenAnswer((_) async => <Book>[existingBook]);
      when(() => mockRepo.createBook(any())).thenAnswer(
        (invocation) async => invocation.positionalArguments.first as Book,
      );

      final app = await buildFormTestApp(
        mockRepo: mockRepo,
        initialArgs: BookFormArgs.manual(initialIsbn: '978-602-412-518-9'),
      );
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // 1. Pastikan aturan D-012: FloatingBottomNav disembunyikan dan tombol Back muncul
      expect(find.byType(FloatingBottomNav), findsNothing);
      expect(find.byKey(const Key('book_form_back_button')), findsOneWidget);

      // 2. Pastikan ISBN fallback manual terbawa
      expect(find.text('9786024125189'), findsOneWidget);

      // 3. Uji validasi BR-02: Tekan Simpan saat judul kosong -> ditolak
      final submitBtn = find.byKey(const Key('book_form_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Judul buku wajib diisi.'), findsOneWidget);
      verifyNever(() => mockRepo.createBook(any()));

      // 4. Ketik judul & penulis -> GeneratedBookCover otomatis ter-render secara live (F-06)
      await tester.enterText(
        find.byKey(const Key('book_form_title_input')),
        'Filosofi Teras',
      );
      await tester.enterText(
        find.byKey(const Key('book_form_author_input')),
        'Henry Manampiring',
      );
      await tester.pumpAndSettle();

      final coverFinder = find.byType(GeneratedBookCover);
      expect(coverFinder, findsOneWidget);
      expect(
        find.descendant(
          of: coverFinder,
          matching: find.text('Filosofi Teras'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: coverFinder,
          matching: find.text('Henry Manampiring'),
        ),
        findsOneWidget,
      );

      // 5. Simpan buku baru -> memanggil createBook lalu AUTO-NAVIGATE ke Home (/)
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      final captured =
          verify(() => mockRepo.createBook(captureAny())).captured.single
              as Book;
      expect(captured.title, 'Filosofi Teras');
      expect(captured.authors, 'Henry Manampiring');
      expect(captured.isbn, '9786024125189');

      // Pastikan otomatis pindah ke HomeDestination
      expect(find.text('HomeDestination'), findsOneWidget);
    });

    testWidgets(
        'Supports Edit mode (F-08) with reader-friendly copywriting and sends updateBook',
        (tester) async {
      final mockRepo = MockBookRepository();
      when(() => mockRepo.getBooks())
          .thenAnswer((_) async => <Book>[existingBook]);
      when(() => mockRepo.updateBook(any())).thenAnswer(
        (invocation) async => invocation.positionalArguments.first as Book,
      );

      final app = await buildFormTestApp(
        mockRepo: mockRepo,
        initialArgs: BookFormArgs.edit(existingBook),
      );
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.text('Sunting Info Buku'), findsOneWidget);
      expect(find.byKey(const Key('book_form_rescan_button')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('book_form_title_input')),
        'Negeri 5 Menara (Edisi Revisi)',
      );
      await tester.enterText(
        find.byKey(const Key('book_form_notes_input')),
        'Rak Utama Baris 2',
      );

      final submitBtn = find.byKey(const Key('book_form_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      final updated =
          verify(() => mockRepo.updateBook(captureAny())).captured.single
              as Book;
      expect(updated.id, 'bk-1');
      expect(updated.title, 'Negeri 5 Menara (Edisi Revisi)');
      expect(updated.notes, 'Rak Utama Baris 2');
    });

    testWidgets(
        'Navbar pages (/, /books, /scanner, /settings) show 4-tab FloatingBottomNav and NO back button (D-012, D-013)',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockBookRepository();
      when(() => mockRepo.getBooks()).thenAnswer((_) async => const <Book>[]);

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

      // 1. Di HomePage (/): FloatingBottomNav tampil, tidak ada tombol arrow_back
      expect(find.byType(FloatingBottomNav), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_outlined), findsNothing);

      // 2. Pindah ke Rak Buku (/books): FloatingBottomNav tampil, tidak ada tombol arrow_back
      await tester.tap(find.text('Rak Buku'));
      await tester.pumpAndSettle();

      expect(find.text('Rak Bukumu'), findsOneWidget);
      expect(find.byType(FloatingBottomNav), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_outlined), findsNothing);

      // 3. Pindah ke Setelan (/settings): FloatingBottomNav tampil, tidak ada tombol arrow_back
      await tester.tap(find.text('Setelan'));
      await tester.pumpAndSettle();

      expect(find.text('Setelan Tampilan'), findsOneWidget);
      expect(find.byType(FloatingBottomNav), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_outlined), findsNothing);

      // 4. Kembali ke Beranda (/), lalu buka /book/form via "+ Tambah Manual"
      await tester.tap(find.text('Beranda'));
      await tester.pumpAndSettle();

      final manualChip = find.byKey(const Key('manual_input_chip_button'));
      await tester.ensureVisible(manualChip);
      await tester.tap(manualChip);
      await tester.pumpAndSettle();

      // Di BookFormPage (/book/form): FloatingBottomNav hilang, tombol arrow_back muncul!
      expect(find.byType(FloatingBottomNav), findsNothing);
      expect(find.byKey(const Key('book_form_back_button')), findsOneWidget);
    });
  });
}
