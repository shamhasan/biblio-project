import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_3d_button.dart';

class HeroScanCard extends StatelessWidget {
  const HeroScanCard({
    super.key,
    required this.onScanTap,
    required this.onOpenBookshelfTap,
  });

  final VoidCallback onScanTap;
  final VoidCallback onOpenBookshelfTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        boxShadow: AppTokens.shadowMd(brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Tambah koleksi bukumu dengan cepat',
            style: textTheme.headlineMedium?.copyWith(
              color: palette.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Pindai kode batang (Barcode/ISBN) sampul buku bagian belakang untuk mengisi detailnya secara otomatis, atau telusuri rak bukumu.',
            style: textTheme.bodyMedium?.copyWith(
              color: palette.onPrimary.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14.0),
          Wrap(
            spacing: AppTokens.space8,
            runSpacing: AppTokens.space8,
            children: <Widget>[
              // Tombol utama 3D (.btn-hero-main)
              App3DButton(
                key: const Key('hero_scan_isbn_button'),
                onPressed: onScanTap,
                backgroundColor: palette.onPrimary,
                foregroundColor: palette.primary,
                bevelColor: Color.alphaBlend(
                  Colors.black.withValues(alpha: 0.18),
                  palette.onPrimary,
                ),
                icon: Icons.qr_code_scanner_outlined,
                label: 'Pindai ISBN',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
