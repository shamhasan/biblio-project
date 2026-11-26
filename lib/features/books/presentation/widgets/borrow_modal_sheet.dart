import 'package:flutter/material.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_3d_button.dart';
import '../../domain/entities/book.dart';

/// Popup Bottom Sheet Modal untuk mencatat peminjaman buku oleh teman (`F-09`, `D-005`, `D-013`)
/// sesuai `#borrowModal` pada `@docs/mockup_interaktif_lengkap_final_mvp.html` (baris 701-728):
/// - Hanya memuat input `Nama Peminjam *` dan `Tanggal Pinjam *` (`YYYY-MM-DD`).
/// - Tidak mencampur field metadata buku atau status bacaan di dalamnya.
class BorrowModalSheet extends StatefulWidget {
  const BorrowModalSheet({
    super.key,
    required this.book,
    required this.onSubmit,
  });

  final Book book;
  final Future<void> Function(String borrowerName, String borrowedAt) onSubmit;

  /// Menampilkan [BorrowModalSheet] sebagai modal bottom sheet.
  static Future<bool?> show(
    BuildContext context, {
    required Book book,
    required Future<void> Function(String borrowerName, String borrowedAt)
        onSubmit,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return BorrowModalSheet(
          book: book,
          onSubmit: onSubmit,
        );
      },
    );
  }

  @override
  State<BorrowModalSheet> createState() => _BorrowModalSheetState();
}

class _BorrowModalSheetState extends State<BorrowModalSheet> {
  late final TextEditingController _borrowerController;
  late final TextEditingController _dateController;
  String? _borrowerError;
  String? _dateError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _borrowerController = TextEditingController(
      text: widget.book.isBorrowed ? widget.book.borrowerName : '',
    );

    final initialDate = (widget.book.isBorrowed &&
            widget.book.borrowedAt.trim().isNotEmpty)
        ? widget.book.borrowedAt.trim()
        : _formatDateYyyyMmDd(DateTime.now());
    _dateController = TextEditingController(text: initialDate);
  }

  @override
  void dispose() {
    _borrowerController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  static String _formatDateYyyyMmDd(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_dateController.text.trim()) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked != null && mounted) {
      setState(() {
        _dateController.text = _formatDateYyyyMmDd(picked);
        _dateError = null;
      });
    }
  }

  Future<void> _handleSave() async {
    if (_isSubmitting) return;

    final cleanName = _borrowerController.text.trim();
    final cleanDate = _dateController.text.trim();

    String? nextNameError;
    String? nextDateError;

    if (cleanName.isEmpty) {
      nextNameError = 'Nama peminjam wajib diisi.';
    }
    if (cleanDate.isEmpty) {
      nextDateError = 'Tanggal pinjam wajib diisi.';
    }

    if (nextNameError != null || nextDateError != null) {
      setState(() {
        _borrowerError = nextNameError;
        _dateError = nextDateError;
      });
      return;
    }

    setState(() {
      _borrowerError = null;
      _dateError = null;
      _isSubmitting = true;
    });

    try {
      await widget.onSubmit(cleanName, cleanDate);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final message = error is AppException
          ? error.message
          : 'Belum dapat menyimpan catatan pinjaman. Silakan coba lagi.';
      setState(() {
        _borrowerError = message;
      });
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: !_isSubmitting,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppTokens.space12,
          AppTokens.space12,
          AppTokens.space12,
          bottomInset + AppTokens.space12,
        ),
        child: Container(
          key: const Key('borrow_modal_sheet'),
          padding: const EdgeInsets.all(18.0),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            border: Border.all(color: palette.border),
            boxShadow: AppTokens.shadowMd(Theme.of(context).brightness),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
              // Header Modal (.modal-head)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Catat Peminjaman Buku',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    key: const Key('borrow_modal_close_button'),
                    onTap: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    child: Container(
                      width: 36.0,
                      height: 36.0,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.border),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.close_outlined,
                        size: 16,
                        color: palette.text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space8),

              Text(
                'Catat teman yang meminjam buku "${widget.book.title}" tanpa mengubah status bacaanmu.',
                style: textTheme.bodySmall?.copyWith(
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: AppTokens.space12),

              // Field 1: Nama Peminjam *
              Text(
                'Nama Peminjam *',
                style: textTheme.labelMedium?.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTokens.space4),
              TextField(
                key: const Key('borrow_modal_name_input'),
                controller: _borrowerController,
                readOnly: _isSubmitting,
                keyboardType: TextInputType.name,
                style: textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Contoh: Raka Pratama',
                  errorText: _borrowerError,
                ),
                onChanged: (_) {
                  if (_borrowerError != null) {
                    setState(() => _borrowerError = null);
                  }
                },
              ),
              const SizedBox(height: AppTokens.space12),

              // Field 2: Tanggal Pinjam *
              Text(
                'Tanggal Pinjam *',
                style: textTheme.labelMedium?.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTokens.space4),
              TextField(
                key: const Key('borrow_modal_date_input'),
                controller: _dateController,
                readOnly: _isSubmitting,
                keyboardType: TextInputType.datetime,
                style: textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'YYYY-MM-DD',
                  errorText: _dateError,
                  suffixIcon: IconButton(
                    key: const Key('borrow_modal_pick_date_button'),
                    icon: Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: palette.textMuted,
                    ),
                    tooltip: 'Pilih Tanggal',
                    onPressed: _isSubmitting ? null : _pickDate,
                  ),
                ),
                onChanged: (_) {
                  if (_dateError != null) {
                    setState(() => _dateError = null);
                  }
                },
              ),
              const SizedBox(height: 14.0),

              // Tombol Batal & Simpan Pinjaman 3D
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 10,
                    child: OutlinedButton(
                      key: const Key('borrow_modal_cancel_button'),
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: AppTokens.space8),
                  Expanded(
                    flex: 14,
                    child: App3DButton(
                      key: const Key('borrow_modal_submit_button'),
                      onPressed: _isSubmitting ? null : _handleSave,
                      isLoading: _isSubmitting,
                      loadingLabel: 'Menyimpan...',
                      label: 'Simpan Pinjaman',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
