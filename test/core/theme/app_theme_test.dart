import 'package:book_inventory_apps/core/config/app_preferences.dart';
import 'package:book_inventory_apps/core/theme/app_colors.dart';
import 'package:book_inventory_apps/core/theme/app_theme.dart';
import 'package:book_inventory_apps/core/theme/app_tokens.dart';
import 'package:book_inventory_apps/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppTheme & Design Tokens', () {
    test(
        'Light and Dark color tokens match @docs/DESIGN_SYSTEM.md & HTML mockups',
        () {
      final lightTheme = AppTheme.light();
      final darkTheme = AppTheme.dark();

      final lightPalette = lightTheme.extension<AppColorPalette>()!;
      final darkPalette = darkTheme.extension<AppColorPalette>()!;

      expect(lightPalette.primary, const Color(0xFF3E6251));
      expect(lightPalette.secondary, const Color(0xFFB34B24));
      expect(lightPalette.background, const Color(0xFFFAF6F0));
      expect(lightPalette.surface, const Color(0xFFFFFFFF));
      expect(lightPalette.error, const Color(0xFFB8332A));
      expect(lightPalette.successBg, const Color(0x242E6F40));
      expect(lightPalette.warningBg, const Color(0x2ED99B26));
      expect(lightPalette.errorBg, const Color(0x24B8332A));
      expect(lightPalette.infoBg, const Color(0x242B5F82));

      expect(darkPalette.primary, const Color(0xFF84B59F));
      expect(darkPalette.secondary, const Color(0xFFF0855E));
      expect(darkPalette.background, const Color(0xFF161615));
      expect(darkPalette.surface, const Color(0xFF232220));
      expect(darkPalette.error, const Color(0xFFEB6A62));
      expect(darkPalette.successBg, const Color(0x296FCF97));
      expect(darkPalette.warningBg, const Color(0x29F2C94C));
      expect(darkPalette.errorBg, const Color(0x29EB6A62));
      expect(darkPalette.infoBg, const Color(0x296CAEE0));

      // GeneratedCoverTone gradients from HTML palette/mockup
      expect(
        GeneratedCoverTone.sage.gradientStart,
        const Color(0xFF1E7D54),
      );
      expect(
        GeneratedCoverTone.terracotta.gradientStart,
        const Color(0xFFB8522E),
      );
      expect(
        GeneratedCoverTone.slate.gradientStart,
        const Color(0xFF2D5D7B),
      );
      expect(
        GeneratedCoverTone.amber.gradientStart,
        const Color(0xFFA46B1D),
      );
    });

    testWidgets('Supports switching between Light/Dark theme and Sans/Serif font',
        (tester) async {
      ThemeMode currentMode = ThemeMode.light;
      AppFontFamily currentFont = AppFontFamily.sans;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              themeMode: currentMode,
              theme: AppTheme.light(fontFamily: currentFont),
              darkTheme: AppTheme.dark(fontFamily: currentFont),
              home: Builder(
                builder: (innerContext) {
                  final palette = innerContext.appColors;
                  final bodyFont =
                      Theme.of(innerContext).textTheme.bodyLarge?.fontFamily ??
                          '';
                  return Scaffold(
                    body: Column(
                      children: [
                        Text('Font: $bodyFont'),
                        Text(
                          'Bg: ${palette.background.toARGB32().toRadixString(16)}',
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              currentMode = ThemeMode.dark;
                              currentFont = AppFontFamily.serif;
                            });
                          },
                          child: const Text('Switch Theme & Font'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      );

      expect(find.text('Font: Plus Jakarta Sans'), findsOneWidget);
      expect(find.text('Bg: fffaf6f0'), findsOneWidget);

      await tester.tap(find.text('Switch Theme & Font'));
      await tester.pumpAndSettle();

      expect(find.text('Font: Lora'), findsOneWidget);
      expect(find.text('Bg: ff161615'), findsOneWidget);
    });

    testWidgets('AppTokens.effectiveDuration respects Reduce Motion setting',
        (tester) async {
      late Duration normalDuration;
      late Duration reducedDuration;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Builder(
            builder: (context) {
              normalDuration = AppTokens.effectiveDuration(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              reducedDuration = AppTokens.effectiveDuration(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(normalDuration, AppTokens.motionBase);
      expect(reducedDuration, Duration.zero);
    });
  });

  group('AppPreferences', () {
    test('Reads defaults and persists GAS URL, theme mode, and font family',
        () async {
      SharedPreferences.setMockInitialValues({});
      final sharedPrefs = await SharedPreferences.getInstance();
      final appPrefs = AppPreferences(sharedPrefs);

      expect(
        appPrefs.getGasWebAppUrl(),
        'https://script.google.com/macros/s/AKfycbwEbNXi3ER8S_70oZJ5JHkqZ9um2wES2eRjpu9Sv37ahDBxmWtdkDxmx2qe-GOON6f42g/exec',
      );
      expect(appPrefs.getThemeMode(), ThemeMode.system);
      expect(appPrefs.getFontFamily(), AppFontFamily.sans);

      await appPrefs.setGasWebAppUrl(
        '  https://script.google.com/macros/s/test-id/exec  ',
      );
      await appPrefs.setThemeMode(ThemeMode.dark);
      await appPrefs.setFontFamily(AppFontFamily.serif);

      expect(
        appPrefs.getGasWebAppUrl(),
        'https://script.google.com/macros/s/test-id/exec',
      );
      expect(appPrefs.getThemeMode(), ThemeMode.dark);
      expect(appPrefs.getFontFamily(), AppFontFamily.serif);

      await appPrefs.setThemeMode(ThemeMode.light);
      expect(appPrefs.getThemeMode(), ThemeMode.light);

      await appPrefs.setThemeMode(ThemeMode.system);
      expect(appPrefs.getThemeMode(), ThemeMode.system);
    });
  });
}
