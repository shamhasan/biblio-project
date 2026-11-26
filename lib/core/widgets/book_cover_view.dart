import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'generated_book_cover.dart';

/// Komponen penampil sampul buku (`BR-05`, `F-06`) yang menampilkan `CachedNetworkImage`
/// bila [coverUrl] non-kosong & valid, dan otomatis melakukan fallback ke [GeneratedBookCover]
/// bila [coverUrl] kosong atau gagal dimuat.
class BookCoverView extends StatelessWidget {
  const BookCoverView({
    super.key,
    required this.title,
    required this.authors,
    this.coverUrl = '',
    this.size = BookCoverSize.small,
    this.tone,
  });

  final String title;
  final String authors;
  final String coverUrl;
  final BookCoverSize size;
  final GeneratedCoverTone? tone;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = coverUrl.trim();
    final fallbackCover = GeneratedBookCover(
      title: title,
      authors: authors,
      size: size,
      tone: tone,
    );

    if (trimmedUrl.isEmpty) {
      return fallbackCover;
    }

    final dimensions = size.size;

    return Container(
      width: dimensions.width,
      height: dimensions.height,
      decoration: BoxDecoration(
        borderRadius: size.borderRadius,
        boxShadow: AppTokens.coverShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: trimmedUrl,
        width: dimensions.width,
        height: dimensions.height,
        fit: BoxFit.cover,
        placeholder: (context, url) => fallbackCover,
        errorWidget: (context, url, error) => fallbackCover,
      ),
    );
  }
}
