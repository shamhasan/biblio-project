import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/book_cover_view.dart';
import '../../../../core/widgets/generated_book_cover.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/reading_status.dart';

/// Kartu item buku pada daftar koleksi (`.book-card`) sesuai `@docs/SCREENS.md`
/// dan `@docs/mockup_interaktif_lengkap_final_mvp.html` (baris 216-231 & 415-470):
/// - Menampilkan `BookCoverView` (`BookCoverSize.small`, otomatis fallback ke `GeneratedBookCover` — `BR-05`).
/// - Menampilkan judul buku, penulis, `StatusBadge` status baca, dan `StatusBadge.borrowed` bila sedang dipinjam.
class BookListCard extends StatelessWidget {
  const BookListCard({
    super.key,
    required this.book,
    required this.onTap,
  });

  final Book book;
  final VoidCallback onTap;

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

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final displayAuthor =
        book.authors.trim().isEmpty ? 'Penulis tidak diketahui' : book.authors;

    return Semantics(
      button: true,
      label: '${book.title}, $displayAuthor',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.space12),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(color: palette.border),
            boxShadow: AppTokens.shadowSm(brightness),
          ),
          child: Row(
            children: <Widget>[
              BookCoverView(
                title: book.title,
                authors: book.authors,
                coverUrl: book.coverUrl,
                size: BookCoverSize.small,
              ),
              const SizedBox(width: AppTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      displayAuthor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Wrap(
                      spacing: AppTokens.space4,
                      runSpacing: AppTokens.space4,
                      children: <Widget>[
                        _buildReadingBadge(book.readingStatus),
                        if (book.isBorrowed)
                          StatusBadge.borrowed(
                            borrowerName: book.borrowerName,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.space8),
              Icon(
                Icons.chevron_right_outlined,
                size: 18,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
