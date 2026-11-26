import 'package:book_inventory_apps/core/router/app_router.dart';
import 'package:book_inventory_apps/core/theme/app_theme.dart';
import 'package:book_inventory_apps/core/widgets/floating_bottom_nav.dart';
import 'package:book_inventory_apps/features/books/domain/entities/book.dart';
import 'package:book_inventory_apps/features/books/domain/entities/book_form_args.dart';
import 'package:book_inventory_apps/features/books/domain/entities/reading_status.dart';
import 'package:book_inventory_apps/features/books/domain/repositories/book_repository.dart';
import 'package:book_inventory_apps/features/books/presentation/pages/book_detail_page.dart';
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

  final sampleBook = Book(
    id: 'bk-1',
    isbn: '9789792248616',
    title: 'Negeri 5 Menara',
    authors: 'Ahmad Fuadi',
    publisher: 'Gramedia',
    publishedYear: '2009',
    coverUrl: '',
    readingStatus: ReadingStatus.reading,
    isBorrowed: false,
    notes: 'Input manual tanpa cover URL.',
    createdAt: '2026-11-25T08:00:00Z',
    updatedAt: '2026-11-25T08:00:00Z',
  );

  Future<Widget> buildDetailTestApp({
    required MockBookRepository mockRepo,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    final router = GoRouter(
      initialLocation: AppRoutes.bookDetail('bk-1'),
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
                final args = state.extra as BookFormArgs?;
                return BookFormPage(args: args);
              },
            ),
            GoRoute(
              path: AppRoutes.bookDetailPattern,
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return BookDetailPage(bookId: id);
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
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    );
  }

  group('BookDetailPage, BorrowModalSheet & Delete Book (T-009: F-07, F-08, F-09, F-10)', () {
    testWidgets(
        'Renders book details, records borrowing via BorrowModalSheet, and clears borrower info on one-tap return (BR-03)',
        (tester) async {
      final mockRepo = MockBookRepository();
      when(() => mockRepo.getBooks())
          .thenAnswer((_) async => <Book>[sampleBook]);
      when(() => mockRepo.updateBook(any())).thenAnswer(
        (invocation) async => invocation.positionalArguments.first as Book,
      );

      final app = await buildDetailTestApp(mockRepo: mockRepo);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // 1. Pastikan aturan D-012: FloatingBottomNav disembunyikan dan tombol Back muncul
      expect(find.byType(FloatingBottomNav), findsNothing);
      expect(find.byKey(const Key('book_detail_back_button')), findsOneWidget);

      // 2. Pastikan metadata awal tampil ("Tersedia di rak pribadi")
      expect(find.byKey(const Key('detail_book_title')), findsOneWidget);
      expect(find.text('Gramedia · 2009'), findsOneWidget);
      expect(find.text('Tersedia di rak pribadi'), findsOneWidget);
      expect(find.byKey(const Key('detail_return_button')), findsNothing);

      // 3. Ketuk "Catat Dipinjam Teman" -> membuka BorrowModalSheet
      final borrowBtn = find.byKey(const Key('detail_borrow_button'));
      await tester.ensureVisible(borrowBtn);
      await tester.tap(borrowBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('borrow_modal_sheet')), findsOneWidget);
      expect(find.text('Catat Peminjaman Buku'), findsOneWidget);

      // Validasi nama peminjam kosong ditolak
      await tester.tap(find.byKey(const Key('borrow_modal_submit_button')));
      await tester.pumpAndSettle();
      expect(find.text('Nama peminjam wajib diisi.'), findsOneWidget);

      // Isi nama peminjam & tanggal pinjam lalu simpan
      await tester.enterText(
        find.byKey(const Key('borrow_modal_name_input')),
        'Raka Pratama',
      );
      await tester.enterText(
        find.byKey(const Key('borrow_modal_date_input')),
        '2026-11-26',
      );
      await tester.tap(find.byKey(const Key('borrow_modal_submit_button')));
      await tester.pumpAndSettle();

      // Verifikasi updateBook dipanggil dengan isBorrowed: true tanpa mengubah readingStatus
      final borrowedPayload =
          verify(() => mockRepo.updateBook(captureAny())).captured.single
              as Book;
      expect(borrowedPayload.isBorrowed, isTrue);
      expect(borrowedPayload.borrowerName, 'Raka Pratama');
      expect(borrowedPayload.borrowedAt, '2026-11-26');
      expect(borrowedPayload.readingStatus, ReadingStatus.reading);

      // UI Detail otomatis menampilkan badge Dipinjam & tombol "Tandai Sudah Dikembalikan"
      expect(find.text('Dipinjam: Raka Pratama'), findsOneWidget);
      expect(
        find.text('Dipinjam Raka Pratama (2026-11-26)'),
        findsOneWidget,
      );
      expect(find.text('Ubah Info Peminjam'), findsOneWidget);
      expect(find.byKey(const Key('detail_return_button')), findsOneWidget);

      // 4. Ketuk "Tandai Sudah Dikembalikan" (BR-03: mengosongkan nama & tanggal pinjam)
      final returnBtn = find.byKey(const Key('detail_return_button'));
      await tester.ensureVisible(returnBtn);
      await tester.tap(returnBtn);
      await tester.pumpAndSettle();

      final returnedPayload =
          verify(() => mockRepo.updateBook(captureAny())).captured.single
              as Book;
      expect(returnedPayload.isBorrowed, isFalse);
      expect(returnedPayload.borrowerName, '');
      expect(returnedPayload.borrowedAt, '');
      expect(returnedPayload.readingStatus, ReadingStatus.reading);

      expect(find.text('Tersedia di rak pribadi'), findsOneWidget);
      expect(find.byKey(const Key('detail_return_button')), findsNothing);
    });

    testWidgets(
        'Navigates to BookFormPage in edit mode and deletes book after confirmation dialog (F-08, F-10)',
        (tester) async {
      final mockRepo = MockBookRepository();
      when(() => mockRepo.getBooks())
          .thenAnswer((_) async => <Book>[sampleBook]);
      when(() => mockRepo.deleteBook('bk-1')).thenAnswer((_) async {});

      final app = await buildDetailTestApp(mockRepo: mockRepo);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // 1. Uji navigasi ke Edit Data & Status Baca Buku
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail_edit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Sunting Info Buku'), findsOneWidget);

      // Kembali ke BookDetailPage
      await tester.tap(find.byKey(const Key('book_form_back_button')));
      await tester.pumpAndSettle();

      // 2. Uji Hapus Buku dengan dialog konfirmasi
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail_delete_button')));
      await tester.pumpAndSettle();

      expect(find.text('Hapus Buku dari Koleksi?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('delete_confirm_submit_button')));
      await tester.pumpAndSettle();

      verify(() => mockRepo.deleteBook('bk-1')).called(1);
      expect(find.text('HomeDestination'), findsOneWidget);
    });
  });
}
