import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Komponen penampil pesan galat / timeout (`F-11`) dengan ikon garis monokrom
/// dan tombol pill **Coba Lagi** (`minHeight: 44dp`) sesuai `@docs/DESIGN_SYSTEM.md`
/// dan `.alert-box.alert-err` di `@docs/mockup_interaktif_lengkap_final_mvp.html`.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Gagal memuat data',
    this.retryLabel = 'Coba Lagi',
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.space16),
      decoration: BoxDecoration(
        color: palette.errorBg,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: palette.error),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.error_outline,
                color: palette.error,
                size: 20,
              ),
              const SizedBox(width: AppTokens.space8),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppTokens.space8),
          Text(
            message,
            style: textTheme.bodySmall?.copyWith(
              color: palette.text,
            ),
          ),
          const SizedBox(width: AppTokens.space12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_outlined, size: 18),
              label: Text(retryLabel),
            ),
          ),
        ],
      ),
    );
  }
}
