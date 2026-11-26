import 'package:book_inventory_apps/app.dart';
import 'package:book_inventory_apps/core/config/app_preferences.dart';
import 'package:book_inventory_apps/core/widgets/floating_bottom_nav.dart';
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
    registerFallbackValue(
      Book(
        id: 'fallback-id',
        isbn: '',
        title: 'Fallback',
        authors: '',
        publisher: '',
        publishedYear: '',
        coverUrl: '',
        readingStatus: ReadingStatus.unread,
        isBorrowed: false,
        createdAt: '2026-11-26T00:00:00Z',
        updatedAt: '2026-11-26T00:00:00Z',
      ),
    );
  });

  group('E2E App Flow Integration Test (T-010: AC-01 s.d. AC-06)', () {
    late List<Book> inMemoryBooks;
    late MockBookRepository mockRepo;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        AppPreferences.keyGasWebAppUrl:
            'https://script.google.com/macros/s/AKfycbwEbNXi3ER8S_70oZJ5JHkqZ9um2wES2eRjpu9Sv37ahDBxmWtdkDxmx2qe-GOON6f42g/exec',
        AppPreferences.keyThemeMode: 'light',
        AppPreferences.keyFontFamily: 'sans',
      });
      prefs = await SharedPreferences.getInstance();

      inMemoryBooks = <Book>[
        Book(
          id: 'bk-init-1',
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

      mockRepo = MockBookRepository();

      when(() => mockRepo.getBooks()).thenAnswer((_) async => List<Book>.from(inMemoryBooks));

      when(() => mockRepo.createBook(any())).thenAnswer((invocation) async {
        final newBook = invocation.positionalArguments.first as Book;
        inMemoryBooks.add(newBook);
        return newBook;
      });

      when(() => mockRepo.updateBook(any())).thenAnswer((invocation) async {
        final updatedBook = invocation.positionalArguments.first as Book;
        final index = inMemoryBooks.indexWhere((b) => b.id == updatedBook.id);
        if (index != -1) {
          inMemoryBooks[index] = updatedBook;
        }
        return updatedBook;
      });

      when(() => mockRepo.deleteBook(any())).thenAnswer((invocation) async {
        final id = invocation.positionalArguments.first as String;
        inMemoryBooks.removeWhere((b) => b.id == id);
      });
    });

    testWidgets(
        'Full App Journey: Beranda -> Tambah Buku Manual -> Detail & Pinjam Teman -> Kembalikan -> Hapus -> Ganti Tema/Font',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2240);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Luncurkan Aplikasi
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

      // Verifikasi Beranda: sapaan ramah, ringkasan koleksi, FloatingBottomNav 4-tab
      expect(find.byType(FloatingBottomNav), findsOneWidget);
      expect(find.text('Negeri 5 Menara'), findsWidgets);
      expect(find.text('Ringkasan Rak Buku'), findsOneWidget);

      // 2. Buka formulir tambah buku dari Rak Buku (F-03, F-05)
      // Tap tab Rak Buku
      await tester.tap(find.text('Rak Buku'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bookshelf_manual_input_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('bookshelf_manual_input_button')));
      await tester.pumpAndSettle();

      // Di BookFormPage: navbar disembunyikan, tombol back tampil (D-012)
      expect(find.byType(FloatingBottomNav), findsNothing);
      expect(find.byKey(const Key('book_form_back_button')), findsOneWidget);

      // Isi form buku baru: Laskar Pelangi
      await tester.enterText(
        find.byKey(const Key('book_form_isbn_input')),
        '9789793062792',
      );
      await tester.enterText(
        find.byKey(const Key('book_form_title_input')),
        'Laskar Pelangi',
      );
      await tester.enterText(
        find.byKey(const Key('book_form_author_input')),
        'Andrea Hirata',
      );
      await tester.pumpAndSettle();

      // Tekan tombol Simpan 3D
      final saveBtn = find.byKey(const Key('book_form_submit_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verifikasi: createBook terpanggil dan auto-navigate langsung ke Beranda (D-013)
      verify(() => mockRepo.createBook(any(that: isA<Book>()))).called(1);
      expect(find.byType(FloatingBottomNav), findsOneWidget);
      expect(find.text('Laskar Pelangi'), findsWidgets);

      // Tunggu hingga SnackBar selesai agar tidak menghalangi interaksi modal
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // 3. Masuk ke halaman Detail Buku (F-07)
      final bookCard = find.text('Laskar Pelangi').first;
      await tester.ensureVisible(bookCard);
      await tester.tap(bookCard);
      await tester.pumpAndSettle();

      // Di BookDetailPage: navbar disembunyikan, back button tampil
      expect(find.byType(FloatingBottomNav), findsNothing);
      expect(find.byKey(const Key('book_detail_back_button')), findsOneWidget);
      expect(find.byKey(const Key('detail_book_title')), findsOneWidget);

      // 4. Catat Peminjaman oleh Teman (F-09)
      final borrowBtn = find.byKey(const Key('detail_borrow_button'));
      await tester.ensureVisible(borrowBtn);
      await tester.tap(borrowBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('borrow_modal_sheet')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('borrow_modal_name_input')),
        'Bayu Pratama',
      );
      await tester.enterText(
        find.byKey(const Key('borrow_modal_date_input')),
        '2026-11-26',
      );
      final submitBorrowBtn = find.byKey(const Key('borrow_modal_submit_button'));
      await tester.ensureVisible(submitBorrowBtn);
      await tester.tap(submitBorrowBtn);
      await tester.pumpAndSettle();

      // Verifikasi status peminjaman tersimpan
      expect(find.text('Dipinjam Bayu Pratama (2026-11-26)'), findsOneWidget);
      expect(find.byKey(const Key('detail_return_button')), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // 5. Kembalikan Buku (BR-03)
      final returnBtn = find.byKey(const Key('detail_return_button'));
      await tester.ensureVisible(returnBtn);
      await tester.tap(returnBtn);
      await tester.pumpAndSettle();

      // Verifikasi peminjam terhapus dan kembali tersedia
      expect(find.text('Tersedia di rak pribadi'), findsOneWidget);
      expect(find.byKey(const Key('detail_return_button')), findsNothing);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // 6. Hapus Buku (F-10)
      final deleteBtn = find.byKey(const Key('detail_delete_button'));
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Hapus Buku dari Koleksi?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('delete_confirm_submit_button')));
      await tester.pumpAndSettle();

      verify(() => mockRepo.deleteBook(any())).called(1);
      // Kembali ke Beranda dan buku sudah terhapus
      expect(find.byType(FloatingBottomNav), findsOneWidget);
      expect(find.text('Laskar Pelangi'), findsNothing);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // 7. Navigasi ke Setelan & Ubah Preferensi Tema/Font (F-13)
      await tester.tap(find.text('Setelan'));
      await tester.pumpAndSettle();

      expect(find.text('Setelan Tampilan'), findsOneWidget);
      expect(find.text('Tema Tampilan'), findsOneWidget);
      expect(find.text('Gaya Huruf (Tipografi)'), findsOneWidget);

      // Ubah tema ke Gelap
      await tester.tap(find.byKey(const Key('theme_dark_button')));
      await tester.pumpAndSettle();
      expect(prefs.getString(AppPreferences.keyThemeMode), equals('dark'));

      // Ubah font ke Serif
      await tester.tap(find.byKey(const Key('font_serif_button')));
      await tester.pumpAndSettle();
      expect(prefs.getString(AppPreferences.keyFontFamily), equals('serif'));
    });
  });
}
