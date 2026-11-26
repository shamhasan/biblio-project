import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Varian semantik `StatusBadge` sesuai `@docs/DESIGN_SYSTEM.md` dan CSS `.badge`
/// pada `@docs/mockup_interaktif_lengkap_final_mvp.html`.
enum StatusBadgeType {
  unread,
  reading,
  finished,
  borrowed,
}

/// Komponen badge status baca dan status pinjam yang terpisah (`F-01`, `F-07`, `F-09`).
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.type,
    this.customLabel,
  });

  /// Badge untuk status `Belum Dibaca` (`unread`).
  const StatusBadge.unread({super.key})
      : type = StatusBadgeType.unread,
        customLabel = null;

  /// Badge untuk status `Sedang Dibaca` (`reading`).
  const StatusBadge.reading({super.key})
      : type = StatusBadgeType.reading,
        customLabel = null;

  /// Badge untuk status `Selesai` (`finished`).
  const StatusBadge.finished({super.key})
      : type = StatusBadgeType.finished,
        customLabel = null;

  /// Badge untuk status `Dipinjam` (`borrowed`), opsional menyertakan nama peminjam.
  factory StatusBadge.borrowed({
    Key? key,
    String? borrowerName,
  }) {
    final cleanName = borrowerName?.trim() ?? '';
    final label = cleanName.isEmpty ? 'Dipinjam' : 'Dipinjam: $cleanName';
    return StatusBadge(
      key: key,
      type: StatusBadgeType.borrowed,
      customLabel: label,
    );
  }

  final StatusBadgeType type;
  final String? customLabel;

  String get _defaultLabel {
    switch (type) {
      case StatusBadgeType.unread:
        return 'Belum Dibaca';
      case StatusBadgeType.reading:
        return 'Sedang Dibaca';
      case StatusBadgeType.finished:
        return 'Selesai';
      case StatusBadgeType.borrowed:
        return 'Dipinjam';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;

    final (Color bgColor, Color fgColor) = switch (type) {
      StatusBadgeType.unread => (palette.surfaceAlt, palette.textMuted),
      StatusBadgeType.reading => (palette.infoBg, palette.info),
      StatusBadgeType.finished => (palette.successBg, palette.success),
      StatusBadgeType.borrowed => (palette.warningBg, palette.secondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space8,
        vertical: 3.0,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      ),
      child: Text(
        customLabel ?? _defaultLabel,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
