import 'package:dio/dio.dart';

import 'app_exception.dart';

/// Pemeta galat HTTP (`DioException`) dan envelope error JSON Google Apps Script
/// menjadi subclass [AppException] dengan pesan ramah pengguna (`@docs/ARCHITECTURE.md`).
abstract final class ErrorMapper {
  /// Memetakan kode error standar dari JSON GAS App (`@docs/API_SPEC.md`).
  static AppException mapGasError({
    required String? code,
    required String? message,
  }) {
    final cleanMessage = (message != null && message.trim().isNotEmpty)
        ? message.trim()
        : 'Terjadi kesalahan pada Google Apps Script.';

    switch (code) {
      case 'DUPLICATE_ISBN':
        return DuplicateIsbnException(cleanMessage);
      case 'NOT_FOUND':
        return NotFoundException(cleanMessage);
      case 'VALIDATION_ERROR':
        return ValidationException(cleanMessage);
      case 'INTERNAL_ERROR':
      default:
        return ServerException(cleanMessage, code ?? 'INTERNAL_ERROR');
    }
  }

  /// Memetakan [Object] error (termasuk [DioException] dan [AppException]) ke [AppException].
  static AppException mapException(Object error) {
    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const TimeoutException();

        case DioExceptionType.connectionError:
          return const NetworkException();

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final data = error.response?.data;
          if (data is Map<String, dynamic> && data['error'] is Map) {
            final errMap = data['error'] as Map;
            return mapGasError(
              code: errMap['code']?.toString(),
              message: errMap['message']?.toString(),
            );
          }
          if (statusCode == 404) {
            return const NotFoundException();
          }
          if (statusCode == 409) {
            return const DuplicateIsbnException(
              'Buku dengan ISBN ini sudah terdaftar di koleksi.',
            );
          }
          if (statusCode == 400) {
            return const ValidationException(
              'Permintaan tidak valid. Periksa kembali data buku.',
            );
          }
          return ServerException(
            'Server mengembalikan kode status HTTP ${statusCode ?? "tidak dikenal"}.',
          );

        case DioExceptionType.cancel:
          return const NetworkException('Permintaan jaringan dibatalkan.');

        case DioExceptionType.badCertificate:
        case DioExceptionType.unknown:
        default:
          return const NetworkException();
      }
    }

    if (error is FormatException) {
      return const ServerException(
        'Format respons dari server tidak dikenali. Pastikan URL deployment GAS App benar.',
      );
    }

    return ServerException(error.toString());
  }
}
