import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/greeting_helper.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_form_args.dart';
import '../providers/books_provider.dart';
import '../widgets/book_list_card.dart';
import '../widgets/collection_summary_row.dart';
import '../widgets/hero_scan_card.dart';

/// Layar Beranda Utama (`HomePage`, rute `/`, Tab 0 pada `FloatingBottomNav`) (`F-01`, `D-013`):
/// - Menampilkan Header Sapaan berukuran besar (`28sp`) dengan **animasi menulis (typewriter effect)**
///   setiap kali pengguna tiba di halaman Beranda.
/// - Menampilkan `HeroScanCard`, `CollectionSummaryRow` (Ringkasan Rak Buku), dan pratinjau
///   buku terbaru beserta pintasan menuju halaman katalog penuh `BookshelfPage` (`/books`).
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, this.nowOverride});

  /// Opsional untuk pengujian deterministik sapaan waktu pada widget test.
  final DateTime? nowOverride;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _typewriterController;
  late final Animation<double> _typewriterAnimation;
  late final String _fullGreeting;

  @override
  void initState() {
    super.initState();
    _fullGreeting = GreetingHelper.getGreeting(widget.nowOverride);
    _typewriterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _typewriterAnimation = CurvedAnimation(
      parent: _typewriterController,
      curve: Curves.easeOutCubic,
    );
    _typewriterController.forward();
  }

  @override
  void dispose() {
    _typewriterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final booksAsync = ref.watch(booksProvider);
    final stats = ref.watch(bookCollectionStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18.0, AppTokens.space16, 18.0, 104.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Header Sapaan Besar (28sp) dengan Animasi Menulis + Tombol Ikon Setelan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: AnimatedBuilder(
                  animation: _typewriterAnimation,
                  builder: (context, _) {
                    final int charCount = disableAnimations
                        ? _fullGreeting.length
                        : (_typewriterAnimation.value * _fullGreeting.length)
                              .ceil()
                              .clamp(1, _fullGreeting.length);
                    final visibleText = _fullGreeting.substring(0, charCount);

                    return Text(
                      visibleText,
                      key: const Key('dynamic_greeting_title'),
                      style: textTheme.headlineLarge?.copyWith(
                        fontSize: 28.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppTokens.space12),
              Semantics(
                button: true,
                label: 'Setelan',
                child: InkWell(
                  key: const Key('header_settings_button'),
                  onTap: () => context.go(AppRoutes.settings),
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  child: Container(
                    width: AppTokens.minTouchTarget,
                    height: AppTokens.minTouchTarget,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.border),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.settings_outlined,
                      size: 18,
                      color: palette.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space16),

          // Hero Scan Card (.hero-scan-card)
          HeroScanCard(
            onScanTap: () => context.go(AppRoutes.scanner),
            onOpenBookshelfTap: () => context.go(AppRoutes.bookshelf),
          ),
          const SizedBox(height: AppTokens.space16),

          // Ringkasan Statistik Rak Buku (.stat-grid)
          CollectionSummaryRow(stats: stats),
          const SizedBox(height: AppTokens.space16),

          // Header Seksi Koleksi Terbaru + Tombol "+ Tambah Manual"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Daftar Bukumu',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              InkWell(
                key: const Key('manual_input_chip_button'),
                onTap: () => context.push(
                  AppRoutes.bookForm,
                  extra: BookFormArgs.manual(),
                ),
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: AppTokens.chipHeight,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space12,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    border: Border.all(color: palette.border),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+ Tambah Manual',
                    style: textTheme.labelMedium?.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space12),

          // Pratinjau Buku di Beranda + Tombol Lihat Semua di Rak Buku
          _buildHomeBooksPreview(context: context, booksAsync: booksAsync),
        ],
      ),
    );
  }

  Widget _buildHomeBooksPreview({
    required BuildContext context,
    required AsyncValue<List<Book>> booksAsync,
  }) {
    final palette = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return booksAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space32),
        child: Column(
          children: <Widget>[
            CircularProgressIndicator(color: palette.primary),
            const SizedBox(height: AppTokens.space12),
            Text(
              'Menyiapkan koleksi bukumu...',
              style: textTheme.bodySmall?.copyWith(color: palette.textMuted),
            ),
          ],
        ),
      ),
      error: (error, _) {
        final message = error is AppException
            ? error.message
            : 'Periksa sambungan internetmu, lalu coba muat kembali.';

        return ErrorRetryView(
          key: const Key('home_error_retry_view'),
          title: 'Belum dapat memuat koleksi buku',
          message: message,
          onRetry: () => ref.read(booksProvider.notifier).refresh(),
        );
      },
      data: (allBooks) {
        if (allBooks.isEmpty) {
          return Container(
            key: const Key('empty_collection_state'),
            padding: const EdgeInsets.all(AppTokens.space24),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              children: <Widget>[
                Icon(
                  Icons.bookmarks_outlined,
                  size: 40,
                  color: palette.textMuted,
                ),
                const SizedBox(height: AppTokens.space12),
                Text(
                  'Rak Bukumu Masih Kosong',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.space4),
                Text(
                  'Mulai catat buku pertamamu dengan memindai kode ISBN atau menambahkannya secara manual.',
                  style: textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.space16),
                ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.scanner),
                  icon: const Icon(Icons.qr_code_scanner_outlined, size: 18),
                  label: const Text('Pindai ISBN'),
                ),
              ],
            ),
          );
        }

        final recentBooks = allBooks.take(4).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ...List<Widget>.generate(recentBooks.length, (index) {
              final book = recentBooks[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == recentBooks.length - 1 ? 0 : 10.0,
                ),
                child: BookListCard(
                  key: Key('book_card_${book.id}'),
                  book: book,
                  onTap: () => context.push(AppRoutes.bookDetail(book.id)),
                ),
              );
            }),
            const SizedBox(height: AppTokens.space12),
            OutlinedButton.icon(
              key: const Key('open_full_bookshelf_button'),
              onPressed: () => context.go(AppRoutes.bookshelf),
              icon: const Icon(Icons.bookmarks_outlined, size: 18),
              label: Text('Lihat Seluruh Rak Buku (${allBooks.length})'),
            ),
          ],
        );
      },
    );
  }
}
