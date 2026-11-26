import 'dart:convert';

import 'package:book_inventory_apps/core/constants/api_constants.dart';
import 'package:book_inventory_apps/core/error/app_exception.dart';
import 'package:book_inventory_apps/core/network/dio_client.dart';
import 'package:book_inventory_apps/features/books/data/datasources/gas_book_datasource.dart';
import 'package:book_inventory_apps/features/books/data/datasources/google_books_datasource.dart';
import 'package:book_inventory_apps/features/books/data/models/book_model.dart';
import 'package:book_inventory_apps/features/books/data/repositories/book_repository_impl.dart';
import 'package:book_inventory_apps/features/books/domain/entities/book.dart';
import 'package:book_inventory_apps/features/books/domain/entities/reading_status.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late String currentGasUrl;
  late GasBookDataSource gasDataSource;
  late GoogleBooksDataSource googleBooksDataSource;
  late BookRepositoryImpl repository;

  const testGasUrl = 'https://script.google.com/macros/s/test-deploy/exec';

  setUp(() {
    mockDio = MockDio();
    currentGasUrl = testGasUrl;
    gasDataSource = GasBookDataSource(
      dio: mockDio,
      getGasUrl: () => currentGasUrl,
    );
    googleBooksDataSource = GoogleBooksDataSource(
      dio: mockDio,
      apiKey: 'test-api-key',
    );
    repository = BookRepositoryImpl(
      gasDataSource: gasDataSource,
      googleBooksDataSource: googleBooksDataSource,
    );
  });

  group('DioClient configuration', () {
    test('Configures 15-second connect, receive, and send timeouts', () {
      final client = DioClient.create();
      expect(client.options.connectTimeout, const Duration(seconds: 15));
      expect(client.options.receiveTimeout, const Duration(seconds: 15));
      expect(client.options.sendTimeout, const Duration(seconds: 15));
      expect(client.options.followRedirects, isTrue);
    });
  });

  group('BookModel JSON serialization', () {
    test('Parses numeric ISBN/year and string boolean from Google Sheets & enforces BR-03', () {
      final json = <String, dynamic>{
        'id': 'bk-100',
        'isbn': 9789792248616,
        'title': 'Negeri 5 Menara',
        'authors': 'Ahmad Fuadi',
        'publisher': 'Gramedia',
        'published_year': 2009,
        'cover_url': '',
        'reading_status': 'reading',
        'is_borrowed': 'FALSE',
        'borrower_name': 'Sisa Nama Lama',
        'borrowed_at': '2026-11-01',
        'notes': 'Catatan',
        'created_at': '2026-11-25T08:00:00Z',
        'updated_at': '2026-11-25T08:00:00Z',
      };

      final model = BookModel.fromJson(json);
      expect(model.isbn, '9789792248616');
      expect(model.publishedYear, '2009');
      expect(model.isBorrowed, isFalse);
      expect(model.borrowerName, '');
      expect(model.borrowedAt, '');

      final roundTrip = model.toJson();
      expect(roundTrip['reading_status'], 'reading');
      expect(roundTrip['is_borrowed'], isFalse);
      expect(roundTrip['borrower_name'], '');
    });
  });

  group('GasBookDataSource & BookRepositoryImpl', () {
    test('Throws EmptyGasUrlException without calling Dio when GAS URL is empty', () async {
      currentGasUrl = '   ';

      await expectLater(
        repository.getBooks(),
        throwsA(isA<EmptyGasUrlException>()),
      );
      verifyZeroInteractions(mockDio);
    });

    test('getBooks parses list of books from GAS JSON response', () async {
      when(
        () => mockDio.get<dynamic>(
          testGasUrl,
          queryParameters: const <String, dynamic>{'action': 'list'},
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: testGasUrl),
          statusCode: 200,
          data: <String, dynamic>{
            'status': 'ok',
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'bk-1',
                'isbn': '9789792248616',
                'title': 'Negeri 5 Menara',
                'authors': 'Ahmad Fuadi',
                'publisher': 'Gramedia Pustaka Utama',
                'published_year': '2009',
                'cover_url': '',
                'reading_status': 'reading',
                'is_borrowed': false,
                'borrower_name': '',
                'borrowed_at': '',
                'notes': 'Buku favorit',
                'created_at': '2026-11-25T08:00:00Z',
                'updated_at': '2026-11-25T08:00:00Z',
              },
            ],
          },
        ),
      );

      final books = await repository.getBooks();
      expect(books, hasLength(1));
      expect(books.first.title, 'Negeri 5 Menara');
      expect(books.first.readingStatus, ReadingStatus.reading);
    });

    test('createBook follows HTTP 302 redirect from script.google.com to script.googleusercontent.com', () async {
      const redirectEchoUrl =
          'https://script.googleusercontent.com/macros/echo?user_content_key=xyz';

      when(
        () => mockDio.post<dynamic>(
          testGasUrl,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: testGasUrl),
          statusCode: 302,
          headers: Headers.fromMap(<String, List<String>>{
            'location': <String>[redirectEchoUrl],
          }),
        ),
      );

      when(
        () => mockDio.get<dynamic>(
          redirectEchoUrl,
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: redirectEchoUrl),
          statusCode: 200,
          data: jsonEncode(<String, dynamic>{
            'status': 'ok',
            'data': <String, dynamic>{
              'id': 'bk-2',
              'isbn': '9786020633176',
              'title': 'Atomic Habits',
            },
          }),
        ),
      );

      final newBook = Book(
        id: 'bk-2',
        isbn: '978-602-063-317-6',
        title: 'Atomic Habits',
        authors: 'James Clear',
        createdAt: '2026-11-25T09:00:00Z',
        updatedAt: '2026-11-25T09:00:00Z',
      );

      final created = await repository.createBook(newBook);
      expect(created.id, 'bk-2');
      expect(created.isbn, '9786020633176');

      verify(
        () => mockDio.post<dynamic>(
          testGasUrl,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).called(1);
      verify(
        () => mockDio.get<dynamic>(
          redirectEchoUrl,
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('Maps GAS error envelope (DUPLICATE_ISBN, NOT_FOUND) and 15s Timeout accurately', () async {
      // 1. DUPLICATE_ISBN
      when(
        () => mockDio.post<dynamic>(
          testGasUrl,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: testGasUrl),
          statusCode: 200,
          data: <String, dynamic>{
            'status': 'error',
            'error': <String, dynamic>{
              'code': 'DUPLICATE_ISBN',
              'message': 'ISBN sudah terdaftar di sheet Books',
            },
          },
        ),
      );

      final book = Book(
        id: 'bk-dup',
        isbn: '9789792248616',
        title: 'Negeri 5 Menara',
        createdAt: '2026-11-25T09:00:00Z',
        updatedAt: '2026-11-25T09:00:00Z',
      );

      await expectLater(
        repository.createBook(book),
        throwsA(isA<DuplicateIsbnException>()),
      );

      // 2. NOT_FOUND on delete
      when(
        () => mockDio.post<dynamic>(
          testGasUrl,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: testGasUrl),
          statusCode: 200,
          data: <String, dynamic>{
            'status': 'error',
            'error': <String, dynamic>{
              'code': 'NOT_FOUND',
              'message': 'ID tidak ditemukan',
            },
          },
        ),
      );

      await expectLater(
        repository.deleteBook('bk-404'),
        throwsA(isA<NotFoundException>()),
      );

      // 3. 15s Timeout on getBooks
      when(
        () => mockDio.get<dynamic>(
          testGasUrl,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: testGasUrl),
          type: DioExceptionType.receiveTimeout,
        ),
      );

      await expectLater(
        repository.getBooks(),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('Enforces BR-02 (non-empty title) before network call', () async {
      final invalidBook = Book(
        id: 'bk-empty',
        title: '   ',
        createdAt: '2026-11-25T09:00:00Z',
        updatedAt: '2026-11-25T09:00:00Z',
      );

      await expectLater(
        repository.createBook(invalidBook),
        throwsA(isA<ValidationException>()),
      );
      verifyZeroInteractions(mockDio);
    });
  });

  group('GoogleBooksDataSource & Quota Fallback (F-03, D-011)', () {
    test('Sends API key, parses volumeInfo, joins authors, extracts 4-digit year, and upgrades http thumbnail to https', () async {
      when(
        () => mockDio.get<dynamic>(
          ApiConstants.googleBooksVolumesUrl,
          queryParameters: const <String, dynamic>{
            'q': 'isbn:9786020633176',
            'key': 'test-api-key',
          },
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(
            path: ApiConstants.googleBooksVolumesUrl,
          ),
          statusCode: 200,
          data: <String, dynamic>{
            'totalItems': 1,
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'volumeInfo': <String, dynamic>{
                  'title': 'Atomic Habits',
                  'authors': <String>['James Clear', 'Translator'],
                  'publisher': 'Gramedia Pustaka Utama',
                  'publishedDate': '2019-09-16',
                  'imageLinks': <String, dynamic>{
                    'thumbnail':
                        'http://books.google.com/books/content?id=123&printsec=frontcover',
                  },
                },
              },
            ],
          },
        ),
      );

      final metadata = await repository.lookupBookByIsbn('978-602-063-317-6');
      expect(metadata, isNotNull);
      expect(metadata!.isbn, '9786020633176');
      expect(metadata.title, 'Atomic Habits');
      expect(metadata.authors, 'James Clear, Translator');
      expect(metadata.publisher, 'Gramedia Pustaka Utama');
      expect(metadata.publishedYear, '2019');
      expect(
        metadata.coverUrl,
        'https://books.google.com/books/content?id=123&printsec=frontcover',
      );
    });

    test('Falls back to OpenLibrary Books API automatically when Google Books returns HTTP 429 Quota Exceeded', () async {
      when(
        () => mockDio.get<dynamic>(
          ApiConstants.googleBooksVolumesUrl,
          queryParameters: const <String, dynamic>{
            'q': 'isbn:9786024246945',
            'key': 'test-api-key',
          },
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: ApiConstants.googleBooksVolumesUrl,
          ),
          response: Response<dynamic>(
            requestOptions: RequestOptions(
              path: ApiConstants.googleBooksVolumesUrl,
            ),
            statusCode: 429,
            data: <String, dynamic>{
              'error': <String, dynamic>{
                'code': 429,
                'message': 'Quota exceeded for quota metric',
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      when(
        () => mockDio.get<dynamic>(
          ApiConstants.openLibraryBooksUrl,
          queryParameters: const <String, dynamic>{
            'bibkeys': 'ISBN:9786024246945',
            'format': 'json',
            'jscmd': 'data',
          },
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(
            path: ApiConstants.openLibraryBooksUrl,
          ),
          statusCode: 200,
          data: <String, dynamic>{
            'ISBN:9786024246945': <String, dynamic>{
              'title': 'Laut Bercerita',
              'authors': <Map<String, dynamic>>[
                <String, dynamic>{'name': 'Leila S. Chudori'},
              ],
              'publishers': <Map<String, dynamic>>[
                <String, dynamic>{'name': 'Kepustakaan Populer Gramedia'},
              ],
              'publish_date': 'October 2017',
              'cover': <String, dynamic>{
                'medium': 'http://covers.openlibrary.org/b/id/8899-M.jpg',
              },
            },
          },
        ),
      );

      final metadata = await repository.lookupBookByIsbn('978-602-424-694-5');
      expect(metadata, isNotNull);
      expect(metadata!.isbn, '9786024246945');
      expect(metadata.title, 'Laut Bercerita');
      expect(metadata.authors, 'Leila S. Chudori');
      expect(metadata.publisher, 'Kepustakaan Populer Gramedia');
      expect(metadata.publishedYear, '2017');
      expect(
        metadata.coverUrl,
        'https://covers.openlibrary.org/b/id/8899-M.jpg',
      );
    });

    test('Returns null when both Google Books (totalItems == 0) and OpenLibrary fallback have no match', () async {
      when(
        () => mockDio.get<dynamic>(
          ApiConstants.googleBooksVolumesUrl,
          queryParameters: const <String, dynamic>{
            'q': 'isbn:9786020001112',
            'key': 'test-api-key',
          },
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(
            path: ApiConstants.googleBooksVolumesUrl,
          ),
          statusCode: 200,
          data: <String, dynamic>{
            'totalItems': 0,
          },
        ),
      );

      when(
        () => mockDio.get<dynamic>(
          ApiConstants.openLibraryBooksUrl,
          queryParameters: const <String, dynamic>{
            'bibkeys': 'ISBN:9786020001112',
            'format': 'json',
            'jscmd': 'data',
          },
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(
            path: ApiConstants.openLibraryBooksUrl,
          ),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      final metadata = await repository.lookupBookByIsbn('978-602-000-111-2');
      expect(metadata, isNull);
    });
  });
}
