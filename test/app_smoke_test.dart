import 'package:book_inventory_apps/app.dart';
import 'package:book_inventory_apps/features/books/domain/entities/book.dart';
import 'package:book_inventory_apps/features/books/domain/repositories/book_repository.dart';
import 'package:book_inventory_apps/features/books/presentation/providers/books_provider.dart';
import 'package:book_inventory_apps/features/settings/presentation/providers/settings_provider.dart';
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

  testWidgets('BookInventoryApp renders HomePage with clean greeting header',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final mockRepo = MockBookRepository();
    when(() => mockRepo.getBooks()).thenAnswer((_) async => const <Book>[]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          bookRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const BookInventoryApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tambah koleksi bukumu dengan cepat'), findsOneWidget);
    expect(find.text('Perpustakaan Mandiri · Sync GAS'), findsNothing);
  });
}
