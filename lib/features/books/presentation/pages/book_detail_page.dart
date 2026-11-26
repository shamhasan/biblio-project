import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_3d_button.dart';
import '../../../../core/widgets/book_cover_view.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/generated_book_cover.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_form_args.dart';
import '../../domain/entities/reading_status.dart';
import '../providers/books_provider.dart';
import '../widgets/borrow_modal_sheet.dart';

/// Layar Detail Buku (`BookDetailPage`, rute `/book/:id`) sesuai `@docs/SCREENS.md`
/// dan `#screen-detail` pada `@docs/mockup_interaktif_lengkap_final_mvp.html`
/// (`F-07`, `F-08`, `F-09`, `F-10`, `F-11`, `BR-03`, `BR-05`, `D-012`, `D-013`).
///
/// Catatan Navigasi (`D-012`):
/// Karena `/book/:id` berada di luar tab `FloatingBottomNav`, navbar bawah disembunyikan
/// dan halaman ini menampilkan tombol **Back** di pojok kiri atas header.
class BookDetailPage extends ConsumerStatefulWidget {
  const BookDetailPage({
    super.key,
    required this.bookId,
  });

  final String bookId;

  @override
  ConsumerState<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends ConsumerState<BookDetailPage> {
  bool _isReturning = false;
  bool _isDeleting = false;

  bool get _isMutating => _isReturning || _isDeleting;

  void _handleBack({bool force = false}) {
    if (_isMutating && !force) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  StatusBadge _buildReadingBadge(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.unread:
        return const StatusBadge.unread();
      case ReadingStatus.reading:
        return const StatusBadge.reading();
      case ReadingStatus.finished:
        return const StatusBadge.finished();
    }
  }

  String _formatPublisherYear(Book book) {
    final pub = book.publisher.trim();
    final year = book.publishedYear.trim();
    if (pub.isNotEmpty && year.isNotEmpty) {
      return '$pub · $year';
    }
    if (pub.isNotEmpty) {
      return pub;
    }
    if (year.isNotEmpty) {
      return year;
    }
    return '-';
  }

  String _formatAvailability(Book book) {
    if (!book.isBorrowed) {
      return 'Tersedia di rak pribadi';
    }
    final name = book.borrowerName.trim();
    final date = book.borrowedAt.trim();
    if (date.isNotEmpty) {
      return 'Dipinjam $name ($date)';
    }
    return 'Dipinjam $name';
  }

  Future<void> _openBorrowModal(Book book) async {
    final saved = await BorrowModalSheet.show(
      context,
      book: book,
      onSubmit: (borrowerName, borrowedAt) async {
        await ref.read(booksProvider.notifier).borrowBook(
              bookId: book.id,
              borrowerName: borrowerName,
              borrowedAt: borrowedAt,
            );
      },
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Catatan peminjaman buku berhasil disimpan.'),
          ),
        );
    }
  }

  Future<void> _markBookReturned(Book book) async {
    if (_isMutating) return;

    setState(() {
      _isReturning = true;
    });

    try {
      await ref.read(booksProvider.notifier).returnBook(book.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Buku ditandai sudah kembali ke rakmu.'),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      final message = error is AppException
          ? error.message
          : 'Belum dapat memperbarui status pengembalian. Silakan coba lagi.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isReturning = false;
        });
      }
    }
  }

  Future<void> _confirmAndDeleteBook(Book book) async {
    if (_isMutating) return;

    final palette = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            side: BorderSide(color: palette.border),
          ),
          title: Text(
            'Hapus Buku dari Koleksi?',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Buku "${book.title}" akan dihapus secara permanen dari daftar koleksimu.',
            style: textTheme.bodyMedium?.copyWith(
              color: palette.textMuted,
            ),
          ),
          actions: <Widget>[
            TextButton(
              key: const Key('delete_confirm_cancel_button'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Batal',
                style: textTheme.labelLarge?.copyWith(
                  color: palette.textMuted,
                ),
              ),
            ),
            ElevatedButton(
              key: const Key('delete_confirm_submit_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.error,
                foregroundColor: palette.onPrimary,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Ya, Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await ref.read(booksProvider.notifier).removeBook(book.id);
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Buku berhasil dihapus dari koleksimu.'),
          ),
        );
      _handleBack(force: true);
    } catch (error) {
      if (!mounted) return;
      final message = error is AppException
          ? error.message
          : 'Belum dapat menghapus buku saat ini. Silakan coba lagi.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final booksAsync = ref.watch(booksProvider);

    return PopScope(
      canPop: !_isMutating,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          18.0,
          AppTokens.space12,
          18.0,
          AppTokens.space24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Top Header (.top-header) dengan tombol Back di kiri atas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Semantics(
                  button: true,
                  label: 'Kembali',
                  child: InkWell(
                    key: const Key('book_detail_back_button'),
                    onTap: _isMutating ? null : _handleBack,
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
                      Icons.arrow_back_outlined,
                      size: 18,
                      color: palette.text,
                    ),
                  ),
                ),
              ),
              Text(
                'Detail Buku',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(
                width: AppTokens.minTouchTarget,
                height: AppTokens.minTouchTarget,
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          booksAsync.when(
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space32),
              child: Center(
                child: CircularProgressIndicator(color: palette.primary),
              ),
            ),
            error: (error, _) => ErrorRetryView(
              title: 'Belum dapat memuat detail buku',
              message: error is AppException
                  ? error.message
                  : 'Periksa sambungan internetmu, lalu coba muat kembali.',
              onRetry: () => ref.read(booksProvider.notifier).refresh(),
            ),
            data: (books) {
              final book = books
                  .where((item) => item.id == widget.bookId)
                  .firstOrNull;

              if (book == null) {
                return Container(
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
                        size: 36,
                        color: palette.textMuted,
                      ),
                      const SizedBox(height: AppTokens.space12),
                      Text(
                        'Buku Tidak Ditemukan',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTokens.space4),
                      Text(
                        'Buku yang kamu pilih mungkin sudah dihapus dari rak koleksimu.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final displayAuthor = book.authors.trim().isEmpty
                  ? 'Penulis tidak diketahui'
                  : book.authors.trim();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // 1. Kartu Hero Sampul Besar (.detail-hero)
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                      border: Border.all(color: palette.border),
                    ),
                    child: Column(
                      children: <Widget>[
                        BookCoverView(
                          title: book.title,
                          authors: book.authors,
                          coverUrl: book.coverUrl,
                          size: BookCoverSize.large,
                        ),
                        const SizedBox(height: AppTokens.space12),
                        Text(
                          book.title,
                          key: const Key('detail_book_title'),
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppTokens.space4),
                        Text(
                          displayAuthor,
                          key: const Key('detail_book_author'),
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppTokens.space8,
                          runSpacing: AppTokens.space4,
                          children: <Widget>[
                            _buildReadingBadge(book.readingStatus),
                            if (book.isBorrowed)
                              StatusBadge.borrowed(
                                key: const Key('detail_borrowed_badge'),
                                borrowerName: book.borrowerName,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.space12),

                  // 2. Kartu Tabel Metadata (.form-card + .info-table)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                      border: Border.all(color: palette.border),
                    ),
                    child: Column(
                      children: <Widget>[
                        _InfoTableRow(
                          label: 'ISBN',
                          value: book.isbn.trim().isEmpty ? '-' : book.isbn,
                          valueKey: const Key('detail_isbn_value'),
                        ),
                        Divider(color: palette.border, height: 1),
                        _InfoTableRow(
                          label: 'Penerbit / Tahun',
                          value: _formatPublisherYear(book),
                          valueKey: const Key('detail_publisher_value'),
                        ),
                        Divider(color: palette.border, height: 1),
                        _InfoTableRow(
                          label: 'Ketersediaan',
                          value: _formatAvailability(book),
                          valueKey: const Key('detail_availability_value'),
                        ),
                        Divider(color: palette.border, height: 1),
                        _InfoTableRow(
                          label: 'Catatan',
                          value: book.notes.trim().isEmpty
                              ? '-'
                              : book.notes.trim(),
                          valueKey: const Key('detail_notes_value'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.space16),

                  // 3. Tombol Aksi 1: Catat Dipinjam Teman / Ubah Info Peminjam (.btn-outline-accent)
                  OutlinedButton.icon(
                    key: const Key('detail_borrow_button'),
                    onPressed:
                        _isMutating ? null : () => _openBorrowModal(book),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: palette.warningBg,
                      foregroundColor: palette.secondary,
                      side: BorderSide(
                        color: palette.secondary,
                        width: 1.5,
                      ),
                    ),
                    icon: Icon(
                      Icons.person_add_alt_1_outlined,
                      size: 18,
                      color: palette.secondary,
                    ),
                    label: Text(
                      book.isBorrowed
                          ? 'Ubah Info Peminjam'
                          : 'Catat Dipinjam Teman',
                      style: textTheme.labelLarge?.copyWith(
                        color: palette.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space8),

                  // 4. Tombol Aksi 2: Tandai Sudah Dikembalikan (.btn-primary 3D, hanya saat isBorrowed == true)
                  if (book.isBorrowed) ...<Widget>[
                    App3DButton(
                      key: const Key('detail_return_button'),
                      onPressed:
                          _isMutating ? null : () => _markBookReturned(book),
                      isLoading: _isReturning,
                      loadingLabel: 'Memperbarui...',
                      icon: Icons.check_outlined,
                      label: 'Tandai Sudah Dikembalikan',
                      width: double.infinity,
                    ),
                    const SizedBox(height: AppTokens.space8),
                  ],

                  // 5. Tombol Aksi 3: Sunting Info & Status Baca (.btn-secondary)
                  OutlinedButton.icon(
                    key: const Key('detail_edit_button'),
                    onPressed: _isMutating
                        ? null
                        : () => context.push(
                              AppRoutes.bookForm,
                              extra: BookFormArgs.edit(book),
                            ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: palette.surface,
                      foregroundColor: palette.text,
                      side: BorderSide(color: palette.border),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Data & Status Baca Buku'),
                  ),
                  const SizedBox(height: AppTokens.space8),

                  // 6. Tombol Aksi 4: Hapus Buku (.btn-danger)
                  OutlinedButton.icon(
                    key: const Key('detail_delete_button'),
                    onPressed: _isMutating
                        ? null
                        : () => _confirmAndDeleteBook(book),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: palette.errorBg,
                      foregroundColor: palette.error,
                      side: BorderSide(color: palette.error),
                    ),
                    icon: _isDeleting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: palette.error,
                            ),
                          )
                        : Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: palette.error,
                          ),
                    label: Text(
                      _isDeleting ? 'Menghapus Buku...' : 'Hapus Buku',
                      style: textTheme.labelLarge?.copyWith(
                        color: palette.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
  }
}

class _InfoTableRow extends StatelessWidget {
  const _InfoTableRow({
    required this.label,
    required this.value,
    this.valueKey,
  });

  final String label;
  final String value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 118.0,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: palette.textMuted,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space8),
          Expanded(
            child: Text(
              value,
              key: valueKey,
              style: textTheme.bodyMedium?.copyWith(
                color: palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
