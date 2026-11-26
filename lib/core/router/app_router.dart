import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/books/domain/entities/book_form_args.dart';
import '../../features/books/presentation/pages/book_detail_page.dart';
import '../../features/books/presentation/pages/book_form_page.dart';
import '../../features/books/presentation/pages/bookshelf_page.dart';
import '../../features/books/presentation/pages/home_page.dart';
import '../../features/books/presentation/pages/scanner_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../widgets/floating_bottom_nav.dart';

/// Konstanta path rute `go_router` sesuai `@docs/ARCHITECTURE.md` dan `D-013`.
abstract final class AppRoutes {
  static const String home = '/';
  static const String bookshelf = '/books';
  static const String scanner = '/scanner';
  static const String bookForm = '/book/form';
  static const String bookDetailPattern = '/book/:id';
  static const String settings = '/settings';

  static String bookDetail(String id) => '/book/$id';

  /// Mengembalikan `true` jika [path] adalah salah satu rute tab utama pada `FloatingBottomNav` (`D-012`, `D-013`).
  static bool isNavbarRoute(String path) {
    final normalized = path.trim().isEmpty ? home : path.trim();
    return normalized == home ||
        normalized == bookshelf ||
        normalized == scanner ||
        normalized == settings;
  }
}

/// Provider untuk [GoRouter] utama aplikasi.
/// Menggunakan `ShellRoute` (`AppNavigationShell`) sehingga `FloatingBottomNav`
/// terpisah sepenuhnya dari halaman, selalu berada di posisi `Stack` paling atas,
/// berukuran *fit-content* di tengah bawah, dan hanya muncul pada halaman tab navbar (`D-012`, `D-013`).
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: <RouteBase>[
      ShellRoute(
        builder: (context, state, child) {
          return AppNavigationShell(
            location: state.uri.path,
            child: child,
          );
        },
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.bookshelf,
            builder: (context, state) => const BookshelfPage(),
          ),
          GoRoute(
            path: AppRoutes.scanner,
            builder: (context, state) => const ScannerPage(),
          ),
          GoRoute(
            path: AppRoutes.bookForm,
            builder: (context, state) {
              final args = state.extra is BookFormArgs
                  ? state.extra as BookFormArgs
                  : null;
              return BookFormPage(args: args);
            },
          ),
          GoRoute(
            path: AppRoutes.bookDetailPattern,
            builder: (context, state) {
              final bookId = state.pathParameters['id'] ?? '';
              return BookDetailPage(bookId: bookId);
            },
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});

/// Shell navigasi tingkat atas yang menempatkan halaman (`child`) di layer bawah
/// dan `FloatingBottomNav` (*fit-content* di dalam `Center`) di layer `Stack` paling atas
/// khusus untuk rute yang termasuk tab navbar (`/`, `/books`, `/scanner`, `/settings`).
class AppNavigationShell extends StatelessWidget {
  const AppNavigationShell({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  bool get _showBottomNav => AppRoutes.isNavbarRoute(location);

  int get _activeIndex {
    if (location == AppRoutes.bookshelf) {
      return 1;
    }
    if (location == AppRoutes.scanner) {
      return 2;
    }
    if (location == AppRoutes.settings) {
      return 3;
    }
    return 0;
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.go(AppRoutes.bookshelf);
      case 2:
        context.go(AppRoutes.scanner);
      case 3:
        context.go(AppRoutes.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            // Layer bawah: Konten halaman yang sedang aktif
            Positioned.fill(
              child: child,
            ),

            // Layer paling atas: Fit-content FloatingBottomNav di tengah bawah layar
            if (_showBottomNav)
              Positioned(
                left: 12.0,
                right: 12.0,
                bottom: 14.0,
                child: Center(
                  child: FloatingBottomNav(
                    key: const Key('global_floating_bottom_nav'),
                    currentIndex: _activeIndex,
                    onTap: (index) => _onNavTap(context, index),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
