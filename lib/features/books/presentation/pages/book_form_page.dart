import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/isbn_normalizer.dart';
import '../../../../core/widgets/app_3d_button.dart';
import '../../../../core/widgets/book_cover_view.dart';
import '../../../../core/widgets/generated_book_cover.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_form_args.dart';
import '../../domain/entities/reading_status.dart';
import '../providers/books_provider.dart';
import '../providers/isbn_lookup_provider.dart';

/// Layar Formulir Tambah & Sunting Buku (`BookFormPage`, rute `/book/form`)
/// dengan copywriting ramah pembaca buku (`F-03`, `F-05`, `F-06`, `F-08`, `D-012`, `D-013`):
/// - Karena `/book/form` berada di luar tab `FloatingBottomNav`, navbar disembunyikan
///   dan tombol Back ditampilkan di pojok kiri atas header.
/// - Setiap kali buku baru berhasil ditambahkan (`addBook`), aplikasi otomatis menavigasi
///   langsung ke `Beranda` (`context.go(AppRoutes.home)`).
class BookFormPage extends ConsumerStatefulWidget {
  const BookFormPage({
    super.key,
    this.args,
  });

  final BookFormArgs? args;

  @override
  ConsumerState<BookFormPage> createState() => _BookFormPageState();
}

class _BookFormPageState extends ConsumerState<BookFormPage> {
  late final TextEditingController _isbnController;
  late final TextEditingController _titleController;
  late final TextEditingController _authorsController;
  late final TextEditingController _notesController;

  late ReadingStatus _readingStatus;
  late String _publisher;
  late String _publishedYear;
  late String _coverUrl;

  String? _titleError;
  String? _isbnError;
  bool _isSubmitting = false;

  Book? get _existingBook => widget.args?.existingBook;
  BookMetadata? get _prefill => widget.args?.prefillMetadata;
  bool get _isEditMode => _existingBook != null;

  @override
  void initState() {
    super.initState();
    final existing = _existingBook;
    final prefill = _prefill;
    final initialIsbn = widget.args?.initialIsbn ?? '';

    _isbnController = TextEditingController(
      text: existing?.isbn ?? prefill?.isbn ?? initialIsbn,
    );
    _titleController = TextEditingController(
      text: existing?.title ?? prefill?.title ?? '',
    );
    _authorsController = TextEditingController(
      text: existing?.authors ?? prefill?.authors ?? '',
    );
    _notesController = TextEditingController(
      text: existing?.notes ?? '',
    );

    _readingStatus = existing?.readingStatus ?? ReadingStatus.unread;
    _publisher = existing?.publisher ?? prefill?.publisher ?? '';
    _publishedYear = existing?.publishedYear ?? prefill?.publishedYear ?? '';
    _coverUrl = existing?.coverUrl ?? prefill?.coverUrl ?? '';
  }

  @override
  void dispose() {
    _isbnController.dispose();
    _titleController.dispose();
    _authorsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _headerTitle {
    if (_isEditMode) {
      return 'Sunting Info Buku';
    }
    return 'Tambah Buku Baru';
  }

  void _handleBack() {
    if (_isSubmitting) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final rawTitle = _titleController.text.trim();
    final rawIsbn = _isbnController.text.trim();
    final normalizedIsbn = IsbnNormalizer.normalize(rawIsbn);

    String? nextTitleError;
    String? nextIsbnError;

    // Validasi BR-02: Judul buku wajib diisi
    if (rawTitle.isEmpty) {
      nextTitleError = 'Judul buku wajib diisi.';
    }

    // Validasi BR-01: Jika ISBN diisi, formatnya harus valid dan tidak boleh duplikat
    if (normalizedIsbn.isNotEmpty) {
      if (!IsbnNormalizer.isValid(normalizedIsbn)) {
        nextIsbnError = 'Masukkan 10 atau 13 digit nomor ISBN yang sesuai.';
      } else {
        final currentBooks =
            ref.read(booksProvider).valueOrNull ?? const <Book>[];
        final checkDuplicate = ref.read(checkDuplicateIsbnProvider);
        final duplicateBook = checkDuplicate(
          rawIsbn: normalizedIsbn,
          existingBooks: currentBooks,
          excludeBookId: _existingBook?.id,
        );
        if (duplicateBook != null) {
          nextIsbnError =
              'ISBN ini sudah digunakan oleh buku "${duplicateBook.title}".';
        }
      }
    }

    if (nextTitleError != null || nextIsbnError != null) {
      setState(() {
        _titleError = nextTitleError;
        _isbnError = nextIsbnError;
      });
      return;
    }

    setState(() {
      _titleError = null;
      _isbnError = null;
      _isSubmitting = true;
    });

    final nowIso = DateTime.now().toUtc().toIso8601String();

    try {
      if (_isEditMode) {
        final existing = _existingBook!;
        final updatedBook = existing.copyWith(
          isbn: normalizedIsbn,
          title: rawTitle,
          authors: _authorsController.text.trim(),
          readingStatus: _readingStatus,
          notes: _notesController.text.trim(),
          updatedAt: nowIso,
        );
        await ref.read(booksProvider.notifier).editBook(updatedBook);

        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Perubahan info buku berhasil disimpan.'),
            ),
          );
        _handleBack();
      } else {
        final newBook = Book(
          id: 'bk-${DateTime.now().millisecondsSinceEpoch}',
          isbn: normalizedIsbn,
          title: rawTitle,
          authors: _authorsController.text.trim(),
          publisher: _publisher,
          publishedYear: _publishedYear,
          coverUrl: _coverUrl,
          readingStatus: _readingStatus,
          isBorrowed: false,
          notes: _notesController.text.trim(),
          createdAt: nowIso,
          updatedAt: nowIso,
        );
        await ref.read(booksProvider.notifier).addBook(newBook);

        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Buku berhasil disimpan ke koleksimu.'),
            ),
          );

        // Selalu auto-navigate langsung ke Beranda (/) setiap kali buku baru ditambahkan
        context.go(AppRoutes.home);
      }
    } catch (error) {
      if (!mounted) return;
      final message = error is AppException
          ? error.message
          : 'Belum dapat menyimpan buku saat ini. Silakan coba lagi.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final hasCoverUrl = _coverUrl.trim().isNotEmpty;

    return PopScope(
      canPop: !_isSubmitting,
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
                    key: const Key('book_form_back_button'),
                    onTap: _isSubmitting ? null : _handleBack,
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space8,
                  ),
                  child: Text(
                    _headerTitle,
                    key: const Key('book_form_header_title'),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (!_isEditMode)
                Semantics(
                  button: true,
                  label: 'Pindai Ulang',
                  child: InkWell(
                    key: const Key('book_form_rescan_button'),
                    onTap: () => context.go(AppRoutes.scanner),
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
                        Icons.qr_code_scanner_outlined,
                        size: 18,
                        color: palette.text,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(
                  width: AppTokens.minTouchTarget,
                  height: AppTokens.minTouchTarget,
                ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Kartu Formulir (.form-card)
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Kotak Pratinjau Sampul Live (.cover-preview-box)
                Container(
                  key: const Key('book_form_cover_preview_box'),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  child: Row(
                    children: <Widget>[
                      BookCoverView(
                        title: _titleController.text,
                        authors: _authorsController.text,
                        coverUrl: _coverUrl,
                        size: BookCoverSize.medium,
                      ),
                      const SizedBox(width: AppTokens.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              hasCoverUrl
                                  ? 'Sampul Buku Otomatis'
                                  : 'Sampul Buku Kustom',
                              style: textTheme.labelMedium?.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppTokens.space4),
                            Text(
                              hasCoverUrl
                                  ? 'Gambar sampul berhasil dimuat dari katalog buku.'
                                  : 'Desain sampul dibuat secara otomatis mengikuti judul dan nama penulis bukumu.',
                              style: textTheme.bodySmall?.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space12),

                // Field 1: ISBN (Opsional)
                const _FormFieldLabel(label: 'Nomor ISBN (Opsional)'),
                const SizedBox(height: AppTokens.space4),
                TextField(
                  key: const Key('book_form_isbn_input'),
                  controller: _isbnController,
                  readOnly: _isSubmitting,
                  keyboardType: TextInputType.text,
                  style: textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 9789792248616',
                    errorText: _isbnError,
                  ),
                  onChanged: (_) {
                    if (_isbnError != null) {
                      setState(() => _isbnError = null);
                    }
                  },
                ),
                const SizedBox(height: AppTokens.space12),

                // Field 2: Judul Buku * (Wajib — BR-02)
                const _FormFieldLabel(label: 'Judul Buku *'),
                const SizedBox(height: AppTokens.space4),
                TextField(
                  key: const Key('book_form_title_input'),
                  controller: _titleController,
                  readOnly: _isSubmitting,
                  keyboardType: TextInputType.text,
                  style: textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Tulis judul buku',
                    errorText: _titleError,
                  ),
                  onChanged: (_) {
                    setState(() {
                      if (_titleError != null) {
                        _titleError = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: AppTokens.space12),

                // Field 3: Penulis
                const _FormFieldLabel(label: 'Penulis'),
                const SizedBox(height: AppTokens.space4),
                TextField(
                  key: const Key('book_form_author_input'),
                  controller: _authorsController,
                  readOnly: _isSubmitting,
                  keyboardType: TextInputType.text,
                  style: textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    hintText: 'Nama penulis buku',
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: AppTokens.space12),

                // Field 4: Status Baca *
                const _FormFieldLabel(label: 'Status Bacaan *'),
                const SizedBox(height: AppTokens.space4),
                DropdownButtonFormField<ReadingStatus>(
                  key: const Key('book_form_reading_status_dropdown'),
                  initialValue: _readingStatus,
                  style: textTheme.bodyMedium,
                  dropdownColor: palette.surface,
                  items: ReadingStatus.values.map((status) {
                    return DropdownMenuItem<ReadingStatus>(
                      value: status,
                      child: Text(status.label),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (nextStatus) {
                          if (nextStatus != null) {
                            setState(() {
                              _readingStatus = nextStatus;
                            });
                          }
                        },
                ),
                const SizedBox(height: AppTokens.space12),

                // Field 5: Catatan Pribadi
                const _FormFieldLabel(label: 'Catatan Pribadi'),
                const SizedBox(height: AppTokens.space4),
                TextField(
                  key: const Key('book_form_notes_input'),
                  controller: _notesController,
                  readOnly: _isSubmitting,
                  maxLines: 3,
                  minLines: 3,
                  keyboardType: TextInputType.multiline,
                  style: textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    hintText:
                        'Letak rak penyimpanan, kesan membaca, atau kutipan favorit...',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space16),

          // Tombol Simpan ke Koleksi (.btn-primary bergaya 3D taktil)
          App3DButton(
            key: const Key('book_form_submit_button'),
            onPressed: _isSubmitting ? null : _handleSubmit,
            isLoading: _isSubmitting,
            loadingLabel: 'Menyimpan...',
            icon: Icons.check_circle_outline,
            label: _isEditMode ? 'Simpan Perubahan' : 'Simpan ke Koleksi',
            width: double.infinity,
          ),
        ],
      ),
    ),
  );
  }
}

class _FormFieldLabel extends StatelessWidget {
  const _FormFieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.appColors.text,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
