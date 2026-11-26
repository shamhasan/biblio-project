import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Varian ukuran sampul buku sesuai `@docs/DESIGN_SYSTEM.md` dan HTML mockup:
/// - `small`: `54 x 78 dp` (List card di HomePage)
/// - `medium`: `68 x 98 dp` (Kotak pratinjau di BookFormPage)
/// - `large`: `118 x 168 dp` (Hero sampul di BookDetailPage)
enum BookCoverSize {
  small(
    size: AppTokens.coverSizeSmall,
    borderRadius: AppTokens.coverRadiusSmallMedium,
    padding: EdgeInsets.fromLTRB(10, 8, 6, 7),
    titleFontSize: 8.5,
    authorFontSize: 6.5,
    titleMaxWidthFactor: 0.74,
  ),
  medium(
    size: AppTokens.coverSizeMedium,
    borderRadius: AppTokens.coverRadiusSmallMedium,
    padding: EdgeInsets.fromLTRB(13, 10, 8, 9),
    titleFontSize: 10.5,
    authorFontSize: 8.0,
    titleMaxWidthFactor: 0.72,
  ),
  large(
    size: AppTokens.coverSizeLarge,
    borderRadius: AppTokens.coverRadiusLarge,
    padding: EdgeInsets.fromLTRB(20, 16, 12, 14),
    titleFontSize: 15.0,
    authorFontSize: 10.5,
    titleMaxWidthFactor: 0.70,
  );

  const BookCoverSize({
    required this.size,
    required this.borderRadius,
    required this.padding,
    required this.titleFontSize,
    required this.authorFontSize,
    required this.titleMaxWidthFactor,
  });

  final Size size;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final double titleFontSize;
  final double authorFontSize;
  final double titleMaxWidthFactor;
}

/// Komponen sampul buku programatis (`F-06`, `BR-05`) saat `cover_url` kosong atau gagal dimuat.
/// Mengikuti spesifikasi CSS `.gen-cover` pada `@docs/palet_tipografi_komponen_buku_final.html`
/// dan `@docs/mockup_interaktif_lengkap_final_mvp.html`:
/// - Gradien warna (`sage`, `terracotta`, `slate`, `amber`).
/// - Lipatan punggung buku di sisi kiri (`11%` lebar, overlay gelap `20%` + garis kanan `10%` putih).
/// - Cincin dekoratif tipis di kanan atas (`top: 14%`, `right: 10%`, diameter `28%` lebar, border `2dp` putih `26%`).
/// - Judul di kiri atas (`maxLines: 3`) dan penulis di kiri bawah (`maxLines: 1`).
class GeneratedBookCover extends StatelessWidget {
  const GeneratedBookCover({
    super.key,
    required this.title,
    required this.authors,
    this.size = BookCoverSize.small,
    this.tone,
  });

  final String title;
  final String authors;
  final BookCoverSize size;
  final GeneratedCoverTone? tone;

  /// Menentukan nada warna sampul secara deterministik dari judul apabila [tone] tidak diberikan.
  static GeneratedCoverTone resolveTone(String title, [GeneratedCoverTone? explicitTone]) {
    if (explicitTone != null) {
      return explicitTone;
    }
    final normalized = title.trim().toLowerCase();
    if (normalized.isEmpty) {
      return GeneratedCoverTone.sage;
    }
    const tones = GeneratedCoverTone.values;
    final hash = normalized.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    return tones[hash % tones.length];
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = title.trim().isEmpty ? 'Judul Buku' : title.trim();
    final effectiveAuthors =
        authors.trim().isEmpty ? 'Penulis' : authors.trim();
    final effectiveTone = resolveTone(effectiveTitle, tone);
    final dimensions = size.size;
    final spineWidth = dimensions.width * 0.11;
    final ringDiameter = dimensions.width * 0.28;

    return Container(
      width: dimensions.width,
      height: dimensions.height,
      decoration: BoxDecoration(
        borderRadius: size.borderRadius,
        boxShadow: AppTokens.coverShadow,
        gradient: LinearGradient(
          begin: const Alignment(-0.7, -0.9),
          end: const Alignment(0.7, 0.9),
          colors: <Color>[
            effectiveTone.gradientStart,
            effectiveTone.gradientEnd,
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          // Lipatan punggung buku di sisi kiri (11% lebar, overlay gelap 20%)
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: spineWidth,
            child: const DecoratedBox(
              key: Key('generated_cover_spine'),
              decoration: BoxDecoration(
                color: AppColors.coverSpineOverlay,
                border: Border(
                  right: BorderSide(
                    color: AppColors.coverSpineBorder,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),

          // Cincin dekoratif tipis di kanan atas (top 14%, right 10%, width 28%)
          Positioned(
            top: dimensions.height * 0.14,
            right: dimensions.width * 0.10,
            width: ringDiameter,
            height: ringDiameter,
            child: const DecoratedBox(
              key: Key('generated_cover_ring'),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(
                    color: AppColors.coverRingBorder,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // Konten teks judul (kiri atas) dan penulis (kiri bawah)
          Padding(
            padding: size.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FractionallySizedBox(
                  widthFactor: size.titleMaxWidthFactor,
                  alignment: Alignment.topLeft,
                  child: Text(
                    effectiveTitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.coverForeground,
                          fontSize: size.titleFontSize,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                  ),
                ),
                Text(
                  effectiveAuthors,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.coverForeground.withValues(alpha: 0.92),
                        fontSize: size.authorFontSize,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
