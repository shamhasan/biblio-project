import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_form_args.dart';
import '../providers/books_provider.dart';
import '../widgets/book_list_card.dart';

/// Halaman Khusus Katalog Penuh (`BookshelfPage`, rute `/books`, Tab 1 pada `FloatingBottomNav`) (`F-12`, `D-013`):
/// - Menampilkan seluruh koleksi buku dari atas sampai bawah dengan kotak pencarian teks
///   (judul, penulis, ISBN) dan filter chips (*Semua*, *Sedang Dibaca*, *Selesai*, *Belum Dibaca*, *Dipinjam Teman*)
///   tanpa terhalang banner utama maupun kartu statistik.
/// - Karena `/books` termasuk tab utama pada `FloatingBottomNav`, halaman ini tidak menampilkan tombol Back.
class BookshelfPage extends ConsumerStatefulWidget {
  const BookshelfPage({super.key});

  @override
  ConsumerState<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends ConsumerState<BookshelfPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(bookSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final booksAsync = ref.watch(booksProvider);
    final stats = ref.watch(bookCollectionStatsProvider);
    final activeFilter = ref.watch(bookFilterProvider);
    final searchQuery = ref.watch(bookSearchQueryProvider);
    final filteredBooks = ref.watch(filteredBooksProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        18.0,
        AppTokens.space16,
        18.0,
        104.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Header Rak Buku + Tombol "+ Tambah Manual"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Rak Bukumu',
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              InkWell(
                key: const Key('bookshelf_manual_input_button'),
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

          // Kotak Pencarian Bundar (.search-box)
          Container(
            constraints: const BoxConstraints(
              minHeight: AppTokens.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.search_outlined,
                  size: 18,
                  color: palette.textMuted,
                ),
                const SizedBox(width: AppTokens.space8),
                Expanded(
                  child: TextField(
                    key: const Key('collection_search_input'),
                    controller: _searchController,
                    style: textTheme.bodyMedium,
                    decoration: const InputDecoration(
                      hintText: 'Cari judul, penulis, atau ISBN...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: AppTokens.space12,
                      ),
                    ),
                    onChanged: (value) {
                      ref
                          .read(bookSearchQueryProvider.notifier)
                          .setQuery(value);
                    },
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  IconButton(
                    key: const Key('clear_search_button'),
                    icon: Icon(
                      Icons.close_outlined,
                      size: 18,
                      color: palette.textMuted,
                    ),
                    tooltip: 'Hapus pencarian',
                    onPressed: () {
                      _searchController.clear();
                      ref.read(bookSearchQueryProvider.notifier).clear();
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10.0),

          // Baris Filter Chips (.chip-row)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _BookshelfFilterChip(
                  key: const Key('filter_chip_all'),
                  label: 'Semua (${stats.totalBooks})',
                  isSelected: activeFilter == BookCollectionFilter.all,
                  onTap: () => ref
                      .read(bookFilterProvider.notifier)
                      .setFilter(BookCollectionFilter.all),
                ),
                const SizedBox(width: 6.0),
                _BookshelfFilterChip(
                  key: const Key('filter_chip_reading'),
                  label: BookCollectionFilter.reading.label,
                  isSelected: activeFilter == BookCollectionFilter.reading,
                  onTap: () => ref
                      .read(bookFilterProvider.notifier)
                      .setFilter(BookCollectionFilter.reading),
                ),
                const SizedBox(width: 6.0),
                _BookshelfFilterChip(
                  key: const Key('filter_chip_finished'),
                  label: BookCollectionFilter.finished.label,
                  isSelected: activeFilter == BookCollectionFilter.finished,
                  onTap: () => ref
                      .read(bookFilterProvider.notifier)
                      .setFilter(BookCollectionFilter.finished),
                ),
                const SizedBox(width: 6.0),
                _BookshelfFilterChip(
                  key: const Key('filter_chip_unread'),
                  label: BookCollectionFilter.unread.label,
                  isSelected: activeFilter == BookCollectionFilter.unread,
                  onTap: () => ref
                      .read(bookFilterProvider.notifier)
                      .setFilter(BookCollectionFilter.unread),
                ),
                const SizedBox(width: 6.0),
                _BookshelfFilterChip(
                  key: const Key('filter_chip_borrowed'),
                  label: BookCollectionFilter.borrowed.label,
                  isSelected: activeFilter == BookCollectionFilter.borrowed,
                  onTap: () => ref
                      .read(bookFilterProvider.notifier)
                      .setFilter(BookCollectionFilter.borrowed),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space12),

          // Daftar Seluruh Buku
          _buildCatalogList(
            context: context,
            booksAsync: booksAsync,
            filteredBooks: filteredBooks,
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogList({
    required BuildContext context,
    required AsyncValue<List<Book>> booksAsync,
    required List<Book> filteredBooks,
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
          key: const Key('bookshelf_error_retry_view'),
          title: 'Belum dapat memuat koleksi buku',
          message: message,
          onRetry: () => ref.read(booksProvider.notifier).refresh(),
        );
      },
      data: (allBooks) {
        if (allBooks.isEmpty) {
          return Container(
            key: const Key('bookshelf_empty_state'),
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

        if (filteredBooks.isEmpty) {
          return Container(
            key: const Key('empty_filter_state'),
            padding: const EdgeInsets.all(AppTokens.space24),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              children: <Widget>[
                Icon(
                  Icons.search_off_outlined,
                  size: 32,
                  color: palette.textMuted,
                ),
                const SizedBox(height: AppTokens.space8),
                Text(
                  'Belum ada buku yang cocok dengan pencarian atau filter ini.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: List<Widget>.generate(filteredBooks.length, (index) {
            final book = filteredBooks[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == filteredBooks.length - 1 ? 0 : 10.0,
              ),
              child: BookListCard(
                key: Key('book_card_${book.id}'),
                book: book,
                onTap: () => context.push(AppRoutes.bookDetail(book.id)),
              ),
            );
          }),
        );
      },
    );
  }
}

class _BookshelfFilterChip extends StatelessWidget {
  const _BookshelfFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final bgColor = isSelected ? palette.primary : palette.surfaceAlt;
    final fgColor = isSelected ? palette.onPrimary : palette.text;
    final borderColor = isSelected ? palette.primary : palette.border;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        child: AnimatedContainer(
          duration: AppTokens.effectiveDuration(
            context,
            duration: AppTokens.motionFast,
          ),
          constraints: const BoxConstraints(
            minHeight: AppTokens.chipHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space12,
            vertical: 6.0,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            border: Border.all(color: borderColor),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
