import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_mapper.dart';
import '../models/book_model.dart';

/// DataSource remote untuk operasi CRUD ke Google Apps Script Web App (`@docs/API_SPEC.md`).
/// Menangani:
/// - Pemeriksaan URL GAS kosong (`EmptyGasUrlException`).
/// - HTTP `302` redirect bawaan Google Apps Script pada metode `POST`.
/// - Pemetaan envelope JSON `{"status": "ok" | "error", ...}` ke [BookModel] atau [AppException].
class GasBookDataSource {
  const GasBookDataSource({
    required Dio dio,
    required String Function() getGasUrl,
  })  : _dio = dio,
        _getGasUrl = getGasUrl;

  final Dio _dio;
  final String Function() _getGasUrl;

  String _requireGasUrl() {
    final url = _getGasUrl().trim();
    if (url.isEmpty) {
      throw const EmptyGasUrlException();
    }
    return url;
  }

  /// `GET <GAS_WEB_APP_URL>?action=list`
  Future<List<BookModel>> fetchBooks() async {
    final gasUrl = _requireGasUrl();
    try {
      final response = await _dio.get<dynamic>(
        gasUrl,
        queryParameters: const <String, dynamic>{'action': 'list'},
      );
      final payload = _parseEnvelope(response.data);
      final rawList = payload['data'];
      if (rawList is! List) {
        return const <BookModel>[];
      }
      return rawList
          .whereType<Map<String, dynamic>>()
          .map(BookModel.fromJson)
          .toList();
    } catch (error) {
      throw ErrorMapper.mapException(error);
    }
  }

  /// `POST <GAS_WEB_APP_URL>` (`action: "create"`)
  Future<BookModel> createBook(BookModel book) async {
    await _postAction(
      action: 'create',
      data: book.toJson(),
    );
    return book;
  }

  /// `POST <GAS_WEB_APP_URL>` (`action: "update"`)
  Future<BookModel> updateBook(BookModel book) async {
    final responsePayload = await _postAction(
      action: 'update',
      data: book.toJson(),
    );
    final respData = responsePayload['data'];
    if (respData is Map<String, dynamic> &&
        respData['updated_at'] is String &&
        (respData['updated_at'] as String).trim().isNotEmpty) {
      return BookModel.fromEntity(
        book.toEntity().copyWith(
              updatedAt: (respData['updated_at'] as String).trim(),
            ),
      );
    }
    return book;
  }

  /// `POST <GAS_WEB_APP_URL>` (`action: "delete"`)
  Future<void> deleteBook(String id) async {
    await _postAction(
      action: 'delete',
      data: <String, dynamic>{'id': id},
    );
  }

  Future<Map<String, dynamic>> _postAction({
    required String action,
    required Map<String, dynamic> data,
  }) async {
    final gasUrl = _requireGasUrl();
    final bodyJson = jsonEncode(<String, dynamic>{
      'action': action,
      'data': data,
    });

    try {
      Response<dynamic> response = await _dio.post<dynamic>(
        gasUrl,
        data: bodyJson,
        options: Options(
          contentType: ApiConstants.gasContentType,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      // Google Apps Script melakukan HTTP 302/303 redirect ke script.googleusercontent.com
      // setelah mengeksekusi doPost(e). Klien wajib melakukan GET ke URL Location tersebut.
      int redirectHop = 0;
      while (_isRedirectStatus(response.statusCode) && redirectHop < 5) {
        final location = response.headers.value('location');
        if (location == null || location.trim().isEmpty) {
          break;
        }
        response = await _dio.get<dynamic>(
          location.trim(),
          options: Options(
            followRedirects: true,
            validateStatus: (status) => status != null && status < 400,
          ),
        );
        redirectHop++;
      }

      return _parseEnvelope(response.data);
    } catch (error) {
      throw ErrorMapper.mapException(error);
    }
  }

  static bool _isRedirectStatus(int? statusCode) {
    return statusCode == 301 ||
        statusCode == 302 ||
        statusCode == 303 ||
        statusCode == 307 ||
        statusCode == 308;
  }

  Map<String, dynamic> _parseEnvelope(dynamic rawData) {
    final Map<String, dynamic> jsonMap;
    if (rawData is Map<String, dynamic>) {
      jsonMap = rawData;
    } else if (rawData is String) {
      final decoded = jsonDecode(rawData);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Envelope JSON bukan objek Map');
      }
      jsonMap = decoded;
    } else {
      throw const FormatException('Format respons GAS tidak didukung');
    }

    final status = jsonMap['status']?.toString().toLowerCase();
    if (status == 'error') {
      final errorObj = jsonMap['error'];
      if (errorObj is Map) {
        throw ErrorMapper.mapGasError(
          code: errorObj['code']?.toString(),
          message: errorObj['message']?.toString(),
        );
      }
      throw ErrorMapper.mapGasError(
        code: 'INTERNAL_ERROR',
        message: jsonMap['message']?.toString(),
      );
    }

    if (status != 'ok') {
      throw const FormatException('Field status bukan "ok"');
    }

    return jsonMap;
  }
}
