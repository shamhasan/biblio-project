import 'package:book_inventory_apps/app.dart';
import 'package:book_inventory_apps/core/config/app_preferences.dart';
import 'package:book_inventory_apps/core/constants/api_constants.dart';
import 'package:book_inventory_apps/core/theme/app_typography.dart';
import 'package:book_inventory_apps/features/books/domain/entities/book.dart';
import 'package:book_inventory_apps/features/books/domain/repositories/book_repository.dart';
import 'package:book_inventory_apps/features/books/presentation/providers/books_provider.dart';
import 'package:book_inventory_apps/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockBookRepository extends Mock implements BookRepository {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('SettingsPage & settingsProvider (F-13, T-005, D-010)', () {
    testWidgets(
      'Uses built-in GAS URL automatically, switches Light/Dark theme, and switches Sans/Serif typography live',
      (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final prefs = await SharedPreferences.getInstance();
        final mockRepo = MockBookRepository();
        when(() => mockRepo.getBooks()).thenAnswer((_) async => const <Book>[]);

        final container = ProviderContainer(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            bookRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const BookInventoryApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Pastikan URL GAS App sudah otomatis terisi dengan URL deployment bawaan (D-010)
        expect(
          container.read(settingsProvider).gasWebAppUrl,
          ApiConstants.defaultGasWebAppUrl,
        );

        // Navigasi ke SettingsPage melalui tombol ikon Setelan di header
        await tester.tap(find.byKey(const Key('header_settings_button')));
        await tester.pumpAndSettle();

        expect(find.text('Setelan Tampilan'), findsOneWidget);
        expect(find.text('Tema Tampilan'), findsOneWidget);
        expect(find.text('Gaya Huruf (Tipografi)'), findsOneWidget);
        expect(find.text('Endpoint Google Apps Script'), findsNothing);

        // Awalnya mengikuti tema perangkat (ThemeMode.system)
        expect(container.read(settingsProvider).themeMode, ThemeMode.system);
        expect(find.byKey(const Key('theme_system_button')), findsOneWidget);
        expect(find.byKey(const Key('theme_light_button')), findsOneWidget);
        expect(find.byKey(const Key('theme_dark_button')), findsOneWidget);

        // 1. Uji ganti tema ke Mode Gelap
        await tester.tap(find.byKey(const Key('theme_dark_button')));
        await tester.pumpAndSettle();

        expect(container.read(settingsProvider).themeMode, ThemeMode.dark);
        expect(prefs.getString(AppPreferences.keyThemeMode), 'dark');

        // 1b. Uji ganti tema kembali ke Otomatis (Ikuti Sistem)
        await tester.tap(find.byKey(const Key('theme_system_button')));
        await tester.pumpAndSettle();
        expect(container.read(settingsProvider).themeMode, ThemeMode.system);
        expect(prefs.getString(AppPreferences.keyThemeMode), 'system');

        // Set kembali ke Gelap untuk pengujian render tema gelap
        await tester.tap(find.byKey(const Key('theme_dark_button')));
        await tester.pumpAndSettle();

        // 2. Uji ganti tipografi ke Serif Buku (Lora)
        expect(container.read(settingsProvider).fontFamily, AppFontFamily.sans);
        final serifButtonFinder = find.byKey(const Key('font_serif_button'));
        await tester.ensureVisible(serifButtonFinder);
        await tester.pumpAndSettle();
        await tester.tap(serifButtonFinder);
        await tester.pumpAndSettle();

        expect(
          container.read(settingsProvider).fontFamily,
          AppFontFamily.serif,
        );
        expect(prefs.getString(AppPreferences.keyFontFamily), 'serif');

        // Pastikan MaterialApp.router langsung merender tema gelap dan font Lora
        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.themeMode, ThemeMode.dark);
        expect(materialApp.darkTheme?.textTheme.bodyLarge?.fontFamily, 'Lora');
      },
    );
  });
}
