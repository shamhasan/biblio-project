import 'package:book_inventory_apps/core/theme/app_colors.dart';
import 'package:book_inventory_apps/core/theme/app_theme.dart';
import 'package:book_inventory_apps/core/widgets/book_cover_view.dart';
import 'package:book_inventory_apps/core/widgets/error_retry_view.dart';
import 'package:book_inventory_apps/core/widgets/floating_bottom_nav.dart';
import 'package:book_inventory_apps/core/widgets/generated_book_cover.dart';
import 'package:book_inventory_apps/core/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('GeneratedBookCover & BookCoverView (BR-05, F-06)', () {
    testWidgets('Renders spine, decorative ring, title, and author',
        (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const GeneratedBookCover(
            title: 'Negeri 5 Menara',
            authors: 'Ahmad Fuadi',
            size: BookCoverSize.large,
            tone: GeneratedCoverTone.sage,
          ),
        ),
      );

      expect(find.byKey(const Key('generated_cover_spine')), findsOneWidget);
      expect(find.byKey(const Key('generated_cover_ring')), findsOneWidget);
      expect(find.text('Negeri 5 Menara'), findsOneWidget);
      expect(find.text('Ahmad Fuadi'), findsOneWidget);
    });

    testWidgets('BookCoverView falls back to GeneratedBookCover when URL empty',
        (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const BookCoverView(
            title: 'Laut Bercerita',
            authors: 'Leila S. Chudori',
            coverUrl: '   ',
            size: BookCoverSize.small,
          ),
        ),
      );

      expect(find.byType(GeneratedBookCover), findsOneWidget);
      expect(find.text('Laut Bercerita'), findsOneWidget);
      expect(find.text('Leila S. Chudori'), findsOneWidget);
    });
  });

  group('StatusBadge', () {
    testWidgets('Renders separate reading and borrowed status badges',
        (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          Column(
            children: <Widget>[
              const StatusBadge.unread(),
              const StatusBadge.reading(),
              const StatusBadge.finished(),
              StatusBadge.borrowed(borrowerName: 'Raka'),
            ],
          ),
        ),
      );

      expect(find.text('Belum Dibaca'), findsOneWidget);
      expect(find.text('Sedang Dibaca'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Dipinjam: Raka'), findsOneWidget);
    });
  });

  group('ErrorRetryView (F-11)', () {
    testWidgets('Displays error message and triggers onRetry callback',
        (tester) async {
      int retryCount = 0;

      await tester.pumpWidget(
        wrapWithTheme(
          ErrorRetryView(
            title: 'Belum dapat memuat koleksi buku',
            message: 'Periksa sambungan internetmu, lalu coba muat kembali.',
            onRetry: () => retryCount++,
          ),
        ),
      );

      expect(find.text('Belum dapat memuat koleksi buku'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();

      expect(retryCount, 1);
    });
  });

  group('FloatingBottomNav (Fit-Content Capsule Dock - D-013)', () {
    testWidgets(
        'Renders all 4 labels (selected and unselected) inside a fit-content capsule dock',
        (tester) async {
      int activeTab = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: AppTheme.light(),
              home: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: FloatingBottomNav(
                    currentIndex: activeTab,
                    onTap: (index) => setState(() => activeTab = index),
                  ),
                ),
              ),
            );
          },
        ),
      );

      // Semua 4 label selalu tampil baik saat terpilih maupun tidak terpilih
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Rak Buku'), findsOneWidget);
      expect(find.text('Pindai'), findsOneWidget);
      expect(find.text('Setelan'), findsOneWidget);

      // Pastikan ikon menu_book_outlined yang kaku tidak digunakan
      expect(find.byIcon(Icons.menu_book_outlined), findsNothing);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.bookmarks_outlined), findsOneWidget);

      // Ketuk tab "Pindai" (index 2)
      await tester.tap(find.text('Pindai'));
      await tester.pumpAndSettle();

      expect(activeTab, 2);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Rak Buku'), findsOneWidget);
      expect(find.text('Pindai'), findsOneWidget);
      expect(find.text('Setelan'), findsOneWidget);
    });
  });
}
