import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/isbn_normalizer.dart';
import '../../domain/entities/book.dart';

/// DataSource remote untuk pencarian metadata buku berdasarkan ISBN (`F-03`, `D-011`):
/// 1. **Primary:** Google Books API (`GET https://www.googleapis.com/books/v1/volumes?q=isbn:<ISBN>&key=<API_KEY>`)
/// 2. **Fallback Otomatis (Saat Limit Kuota Habis HTTP 429/403 atau `totalItems == 0`):**
///    OpenLibrary Books API (`GET https://openlibrary.org/api/books?bibkeys=ISBN:<ISBN>&format=json&jscmd=data`)
/// 3. **Fallback Akhir (`F-05`):** Jika di kedua sumber tidak ditemukan, mengembalikan `null`
///    agar UI mengarahkan pengguna ke **Isi Manual Sekarang** dengan membawa nomor ISBN yang sudah terbaca.
class GoogleBooksDataSource {
  const GoogleBooksDataSource({
    required Dio dio,
    this.apiKey,
  }) : _dio = dio;

  final Dio _dio;

  /// Opsional override kunci API (default menggunakan [ApiConstants.googleBooksApiKey]).
  final String? apiKey;

  static final RegExp _yearRegex = RegExp(r'(\d{4})');

  String get _effectiveApiKey =>
      (apiKey ?? ApiConstants.googleBooksApiKey).trim();

  Future<BookMetadata?> lookupByIsbn(String rawIsbn) async {
    final normalizedIsbn = IsbnNormalizer.normalize(rawIsbn);
    if (normalizedIsbn.isEmpty) {
      return null;
    }

    try {
      final key = _effectiveApiKey;
      final queryParams = <String, dynamic>{
        'q': 'isbn:$normalizedIsbn',
        if (key.isNotEmpty) 'key': key,
      };

      final response = await _dio.get<dynamic>(
        ApiConstants.googleBooksVolumesUrl,
        queryParameters: queryParams,
      );

      final parsed = _parseGoogleBooksResponse(
        rawData: response.data,
        normalizedIsbn: normalizedIsbn,
      );
      if (parsed != null) {
        return parsed;
      }

      // Jika Google Books mengembalikan totalItems == 0, coba fallback ke OpenLibrary
      return await _lookupFromOpenLibraryFallback(normalizedIsbn);
    } on DioException catch (dioError) {
      if (_isQuotaOrRateLimitError(dioError)) {
        // Jika kuota Google Books API habis (HTTP 429 / 403), jalankan fallback OpenLibrary
        final fallbackResult =
            await _lookupFromOpenLibraryFallback(normalizedIsbn);
        if (fallbackResult != null) {
          return fallbackResult;
        }
        return null;
      }
      throw ErrorMapper.mapException(dioError);
    } catch (error) {
      throw ErrorMapper.mapException(error);
    }
  }

  BookMetadata? _parseGoogleBooksResponse({
    required dynamic rawData,
    required String normalizedIsbn,
  }) {
    final Map<String, dynamic>? data = _decodeToMap(rawData);
    if (data == null) {
      return null;
    }

    final totalItems = data['totalItems'];
    if (totalItems is num && totalItems <= 0) {
      return null;
    }

    final items = data['items'];
    if (items is! List || items.isEmpty) {
      return null;
    }

    final firstItem = items.first;
    if (firstItem is! Map<String, dynamic>) {
      return null;
    }

    final volumeInfo = firstItem['volumeInfo'];
    if (volumeInfo is! Map<String, dynamic>) {
      return null;
    }

    final title = (volumeInfo['title']?.toString() ?? '').trim();
    if (title.isEmpty) {
      return null;
    }

    final rawAuthors = volumeInfo['authors'];
    final authors = rawAuthors is List
        ? rawAuthors
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .join(', ')
        : '';

    final publisher = (volumeInfo['publisher']?.toString() ?? '').trim();
    final rawPublishedDate =
        (volumeInfo['publishedDate']?.toString() ?? '').trim();
    final yearMatch = _yearRegex.firstMatch(rawPublishedDate);
    final publishedYear = yearMatch != null ? yearMatch.group(1)! : '';

    String coverUrl = '';
    final imageLinks = volumeInfo['imageLinks'];
    if (imageLinks is Map<String, dynamic>) {
      final rawThumb = (imageLinks['thumbnail'] ??
              imageLinks['smallThumbnail'] ??
              '')
          .toString()
          .trim();
      coverUrl = _ensureHttps(rawThumb);
    }

    return BookMetadata(
      isbn: normalizedIsbn,
      title: title,
      authors: authors,
      publisher: publisher,
      publishedYear: publishedYear,
      coverUrl: coverUrl,
    );
  }

  /// Fallback otomatis ke OpenLibrary Books API ketika kuota Google Books API habis
  /// atau buku tidak ditemukan di indeks Google Books.
  Future<BookMetadata?> _lookupFromOpenLibraryFallback(
    String normalizedIsbn,
  ) async {
    try {
      final bibKey = 'ISBN:$normalizedIsbn';
      final response = await _dio.get<dynamic>(
        ApiConstants.openLibraryBooksUrl,
        queryParameters: <String, dynamic>{
          'bibkeys': bibKey,
          'format': 'json',
          'jscmd': 'data',
        },
      );

      final Map<String, dynamic>? data = _decodeToMap(response.data);
      if (data == null || data.isEmpty) {
        return null;
      }

      final bookObj = data[bibKey];
      if (bookObj is! Map<String, dynamic>) {
        return null;
      }

      final title = (bookObj['title']?.toString() ?? '').trim();
      if (title.isEmpty) {
        return null;
      }

      final rawAuthors = bookObj['authors'];
      final authors = rawAuthors is List
          ? rawAuthors
              .map((item) {
                if (item is Map) {
                  return item['name']?.toString().trim() ?? '';
                }
                return item?.toString().trim() ?? '';
              })
              .where((name) => name.isNotEmpty)
              .join(', ')
          : '';

      String publisher = '';
      final rawPublishers = bookObj['publishers'];
      if (rawPublishers is List && rawPublishers.isNotEmpty) {
        final firstPub = rawPublishers.first;
        if (firstPub is Map) {
          publisher = (firstPub['name']?.toString() ?? '').trim();
        } else if (firstPub != null) {
          publisher = firstPub.toString().trim();
        }
      }

      final rawPublishDate =
          (bookObj['publish_date']?.toString() ?? '').trim();
      final yearMatch = _yearRegex.firstMatch(rawPublishDate);
      final publishedYear = yearMatch != null ? yearMatch.group(1)! : '';

      String coverUrl = '';
      final coverObj = bookObj['cover'];
      if (coverObj is Map) {
        final rawCover = (coverObj['medium'] ??
                coverObj['large'] ??
                coverObj['small'] ??
                '')
            .toString()
            .trim();
        coverUrl = _ensureHttps(rawCover);
      }

      return BookMetadata(
        isbn: normalizedIsbn,
        title: title,
        authors: authors,
        publisher: publisher,
        publishedYear: publishedYear,
        coverUrl: coverUrl,
      );
    } catch (_) {
      // Jika fallback OpenLibrary juga gagal/timeout, kembalikan null agar UI
      // menampilkan tombol "Isi Manual Sekarang" dengan tetap membawa nomor ISBN (F-05).
      return null;
    }
  }

  static bool _isQuotaOrRateLimitError(DioException error) {
    final statusCode = error.response?.statusCode;
    return statusCode == 429 || statusCode == 403;
  }

  static Map<String, dynamic>? _decodeToMap(dynamic rawData) {
    if (rawData is Map<String, dynamic>) {
      return rawData;
    }
    if (rawData is String && rawData.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static String _ensureHttps(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http://')) {
      return 'https://${url.substring('http://'.length)}';
    }
    return url;
  }
}
