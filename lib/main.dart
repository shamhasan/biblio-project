import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/network/dio_client.dart';
import 'features/books/data/datasources/gas_book_datasource.dart';
import 'features/books/data/datasources/google_books_datasource.dart';
import 'features/books/data/repositories/book_repository_impl.dart';
import 'features/books/presentation/providers/books_provider.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  final dio = DioClient.create();

  runApp(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        bookRepositoryProvider.overrideWith((ref) {
          return BookRepositoryImpl(
            gasDataSource: GasBookDataSource(
              dio: dio,
              getGasUrl: () => ref.read(settingsProvider).gasWebAppUrl,
            ),
            googleBooksDataSource: GoogleBooksDataSource(dio: dio),
          );
        }),
      ],
      child: const BookInventoryApp(),
    ),
  );
}
