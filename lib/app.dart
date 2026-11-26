import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

/// Root widget aplikasi Manajemen Buku Mandiri (`@docs/ARCHITECTURE.md`).
/// Memantau perubahan `themeMode` dan `fontFamily` dari [settingsProvider] secara reaktif.
class BookInventoryApp extends ConsumerWidget {
  const BookInventoryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Manajemen Buku',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.light(fontFamily: settings.fontFamily),
      darkTheme: AppTheme.dark(fontFamily: settings.fontFamily),
      routerConfig: router,
    );
  }
}
