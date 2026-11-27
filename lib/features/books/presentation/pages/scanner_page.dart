import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/isbn_normalizer.dart';
import '../../domain/entities/book_form_args.dart';
import '../providers/isbn_lookup_provider.dart';

/// Layar Pemindai Kode Batang ISBN (`ScannerPage`, rute `/scanner`, Tab 2 pada `FloatingBottomNav`)
/// dengan copywriting ramah pembaca buku (`F-02`, `F-03`, `F-04`, `F-05`, `D-012`, `D-013`).
class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({
    super.key,
    this.enableCamera = true,
  });

  final bool enableCamera;

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  MobileScannerController? _scannerController;
  late final AnimationController _laserController;
  late final TextEditingController _manualIsbnController;
  String? _manualIsbnError;
  bool _isNavigatingAway = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _manualIsbnController = TextEditingController();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.enableCamera) {
      _laserController.repeat(reverse: true);
      _scannerController = MobileScannerController(
        formats: const <BarcodeFormat>[
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
        ],
        detectionSpeed: DetectionSpeed.normal,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(isbnLookupProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _laserController.dispose();
    _manualIsbnController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enableCamera || _scannerController == null) return;

    if (state == AppLifecycleState.resumed) {
      final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
      if (isCurrentRoute && !_isNavigatingAway) {
        _laserController.repeat(reverse: true);
        _scannerController?.start();
      }
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _laserController.stop();
      _scannerController?.stop();
    }
  }

  Future<T?> _navigateWithCameraPause<T>(Future<T?> Function() action) async {
    _isNavigatingAway = true;
    _laserController.stop();
    await _scannerController?.stop();

    if (!mounted) return null;
    final result = await action();
    _isNavigatingAway = false;

    if (mounted && widget.enableCamera) {
      _laserController.repeat(reverse: true);
      await _scannerController?.start();
    }
    return result;
  }

  void _handleBarcodeCapture(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && IsbnNormalizer.isValid(rawValue)) {
        ref.read(isbnLookupProvider.notifier).onBarcodeDetected(rawValue);
        break;
      }
    }
  }

  Future<void> _submitTypedIsbn() async {
    final raw = _manualIsbnController.text.trim();
    if (!IsbnNormalizer.isValid(raw)) {
      setState(() {
        _manualIsbnError = 'Masukkan 10 atau 13 digit nomor ISBN yang sesuai.';
      });
      return;
    }

    setState(() {
      _manualIsbnError = null;
    });

    await ref.read(isbnLookupProvider.notifier).onBarcodeDetected(raw);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final lookupState = ref.watch(isbnLookupProvider);
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    ref.listen<IsbnLookupState>(isbnLookupProvider, (previous, next) {
      if (next is IsbnLookupFound && mounted) {
        ref.read(isbnLookupProvider.notifier).reset();
        _navigateWithCameraPause(
          () => context.push(
            AppRoutes.bookForm,
            extra: BookFormArgs.prefill(next.metadata),
          ),
        );
      }
    });

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
          // Top Header tanpa tombol Back (Tab utama navbar sesuai D-012)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Pindai Kode Buku',
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_scannerController != null)
                Semantics(
                  button: true,
                  label: 'Lampu Kilat',
                  child: InkWell(
                    key: const Key('scanner_torch_button'),
                    onTap: () => _scannerController?.toggleTorch(),
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
                        Icons.flash_on_outlined,
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
          const SizedBox(height: AppTokens.space8),

          Text(
            'Arahkan kamera ke garis kode batang (ISBN) di sampul belakang bukumu.',
            style: textTheme.bodyMedium?.copyWith(
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: AppTokens.space12),

          // Viewfinder Kamera
          Container(
            key: const Key('scanner_viewfinder'),
            height: 230.0,
            decoration: BoxDecoration(
              color: AppColors.viewfinderBackground,
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              border: Border.all(
                color: palette.primary,
                width: 2.0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                if (widget.enableCamera && _scannerController != null)
                  Positioned.fill(
                    child: MobileScanner(
                      controller: _scannerController!,
                      onDetect: _handleBarcodeCapture,
                      errorBuilder: (context, error, child) {
                        return _CameraPermissionFallback(
                          onManualInputTap: () => _navigateWithCameraPause(
                            () => context.push(
                              AppRoutes.bookForm,
                              extra: BookFormArgs.manual(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 220.0,
                      height: 110.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        border: Border.all(
                          color: AppColors.scannerFrameBorder,
                          width: 2.0,
                        ),
                      ),
                      child: AnimatedBuilder(
                        animation: _laserController,
                        builder: (context, _) {
                          final progress =
                              disableAnimations ? 0.5 : _laserController.value;
                          final topOffset = 12.0 + (progress * 80.0);
                          return Stack(
                            children: <Widget>[
                              Positioned(
                                top: topOffset,
                                left: 8.0,
                                right: 8.0,
                                child: Container(
                                  height: 2.0,
                                  decoration: const BoxDecoration(
                                    color: AppColors.scannerLaserLine,
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: AppColors.scannerLaserLine,
                                        blurRadius: 8.0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    Text(
                      lookupState is IsbnLookupLoading
                          ? 'Mencari informasi buku...'
                          : 'Arahkan kode batang ke dalam kotak...',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.coverForeground.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),

                if (lookupState is IsbnLookupLoading)
                  Positioned.fill(
                    child: ColoredBox(
                      color: AppColors.viewfinderBackground.withValues(
                        alpha: 0.72,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            CircularProgressIndicator(
                              color: palette.primary,
                            ),
                            const SizedBox(height: AppTokens.space12),
                            Text(
                              'Mencari informasi buku...',
                              style: textTheme.labelMedium?.copyWith(
                                color: AppColors.coverForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space12),

          // Banner Buku Sudah Ada di Rak (Duplikat ISBN)
          if (lookupState is IsbnLookupDuplicate) ...<Widget>[
            Container(
              key: const Key('duplicate_isbn_alert'),
              padding: const EdgeInsets.all(AppTokens.space12),
              decoration: BoxDecoration(
                color: palette.warningBg,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: palette.warning),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: palette.warning,
                      ),
                      const SizedBox(width: AppTokens.space8),
                      Expanded(
                        child: Text(
                          'Buku ini sudah ada di rakmu',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space4),
                  Text(
                    'Buku "${lookupState.existingBook.title}" sudah tercatat di koleksimu. Kamu bisa langsung melihat halaman detailnya.',
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const Key('view_duplicate_detail_button'),
                      onPressed: () {
                        final targetId = lookupState.existingBook.id;
                        ref.read(isbnLookupProvider.notifier).reset();
                        _navigateWithCameraPause(
                          () => context.push(AppRoutes.bookDetail(targetId)),
                        );
                      },
                      child: const Text('Lihat Detail Buku'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space12),
          ],

          // Banner Detail Buku Belum Ditemukan Otomatis
          if (lookupState is IsbnLookupNotFound) ...<Widget>[
            Container(
              key: const Key('not_found_isbn_alert'),
              padding: const EdgeInsets.all(AppTokens.space12),
              decoration: BoxDecoration(
                color: palette.errorBg,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: palette.error),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.error_outline,
                        size: 18,
                        color: palette.error,
                      ),
                      const SizedBox(width: AppTokens.space8),
                      Expanded(
                        child: Text(
                          'Detail buku belum ditemukan secara otomatis',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space4),
                  Text(
                    lookupState.message,
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: const Key('fallback_manual_form_button'),
                      onPressed: () {
                        final scannedIsbn = lookupState.normalizedIsbn;
                        ref.read(isbnLookupProvider.notifier).reset();
                        _navigateWithCameraPause(
                          () => context.push(
                            AppRoutes.bookForm,
                            extra: BookFormArgs.manual(initialIsbn: scannedIsbn),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Isi Manual Sekarang'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space12),
          ],

          // Kartu Fallback Ketik ISBN / Catat Manual
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
                Text(
                  'Kode Batang Sulit Terbaca?',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTokens.space4),
                Text(
                  'Ketik nomor ISBN yang tertera di sampul belakang buku, atau langsung catat buku secara manual.',
                  style: textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(height: AppTokens.space12),
                TextField(
                  key: const Key('scanner_isbn_input'),
                  controller: _manualIsbnController,
                  keyboardType: TextInputType.text,
                  style: textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 978-602-063-317-6',
                    errorText: _manualIsbnError,
                    prefixIcon: Icon(
                      Icons.qr_code_outlined,
                      size: 18,
                      color: palette.textMuted,
                    ),
                  ),
                  onSubmitted: (_) => _submitTypedIsbn(),
                ),
                const SizedBox(height: AppTokens.space12),
                ElevatedButton.icon(
                  key: const Key('lookup_isbn_button'),
                  onPressed:
                      lookupState is IsbnLookupLoading ? null : _submitTypedIsbn,
                  icon: const Icon(Icons.search_outlined, size: 18),
                  label: const Text('Cari Buku dengan ISBN'),
                ),
                const SizedBox(height: AppTokens.space8),
                OutlinedButton.icon(
                  key: const Key('direct_manual_form_button'),
                  onPressed: () {
                    final raw = _manualIsbnController.text.trim();
                    ref.read(isbnLookupProvider.notifier).reset();
                    _navigateWithCameraPause(
                      () => context.push(
                        AppRoutes.bookForm,
                        extra: BookFormArgs.manual(initialIsbn: raw),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_note_outlined, size: 18),
                  label: const Text('Catat Buku Secara Manual'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraPermissionFallback extends StatelessWidget {
  const _CameraPermissionFallback({
    required this.onManualInputTap,
  });

  final VoidCallback onManualInputTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: AppColors.viewfinderBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.no_photography_outlined,
              size: 32,
              color: AppColors.coverForeground,
            ),
            const SizedBox(height: AppTokens.space8),
            Text(
              'Kamera belum dapat diakses. Izinkan akses kamera di pengaturan perangkat atau catat buku secara manual.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.coverForeground,
              ),
            ),
            const SizedBox(height: AppTokens.space12),
            OutlinedButton.icon(
              onPressed: onManualInputTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.coverForeground,
                side: const BorderSide(color: AppColors.scannerFrameBorder),
              ),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Catat Manual'),
            ),
          ],
        ),
      ),
    );
  }
}
