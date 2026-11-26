import 'package:book_inventory_apps/core/theme/app_theme.dart';
import 'package:book_inventory_apps/core/widgets/app_3d_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestable(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('App3DButton Widget Test', () {
    testWidgets('Renders label, icon, and handles tap callback with press feedback',
        (tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        buildTestable(
          App3DButton(
            key: const Key('test_3d_btn'),
            onPressed: () => tapCount++,
            label: 'Mulai Pindai',
            icon: Icons.qr_code_scanner_outlined,
          ),
        ),
      );

      expect(find.text('Mulai Pindai'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_outlined), findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('test_3d_btn'))));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tapCount, equals(1));
    });

    testWidgets('Does not invoke onPressed when disabled (onPressed == null)',
        (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const App3DButton(
            key: Key('test_disabled_btn'),
            onPressed: null,
            label: 'Tersimpan',
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('test_disabled_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Tersimpan'), findsOneWidget);
    });

    testWidgets('Shows CircularProgressIndicator and loadingLabel when isLoading is true',
        (tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        buildTestable(
          App3DButton(
            key: const Key('test_loading_btn'),
            onPressed: () => tapCount++,
            label: 'Simpan',
            loadingLabel: 'Menyimpan...',
            isLoading: true,
          ),
        ),
      );

      expect(find.text('Menyimpan...'), findsOneWidget);
      expect(find.text('Simpan'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byKey(const Key('test_loading_btn')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tapCount, equals(0));
    });
  });
}
