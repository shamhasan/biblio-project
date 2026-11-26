import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../providers/books_provider.dart';

/// Baris 3 kartu statistik ringkasan rak buku (`.stat-grid` & `.stat-card`)
/// dengan copywriting ramah pembaca tanpa label teknis (`D-013`).
class CollectionSummaryRow extends StatelessWidget {
  const CollectionSummaryRow({
    super.key,
    required this.stats,
  });

  final BookCollectionStats stats;

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Ringkasan Rak Buku',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTokens.space8),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                key: const Key('stat_total_books'),
                label: 'Total Buku',
                value: '${stats.totalBooks}',
                valueColor: palette.text,
              ),
            ),
            const SizedBox(width: AppTokens.space8),
            Expanded(
              child: _StatCard(
                key: const Key('stat_reading_books'),
                label: 'Dibaca',
                value: '${stats.readingBooks}',
                valueColor: palette.info,
              ),
            ),
            const SizedBox(width: AppTokens.space8),
            Expanded(
              child: _StatCard(
                key: const Key('stat_borrowed_books'),
                label: 'Dipinjam',
                value: '${stats.borrowedBooks}',
                valueColor: palette.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
