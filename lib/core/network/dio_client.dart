import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

/// Pembangun instance [Dio] standar dengan timeout `15 detik` dan dukungan redirect
/// sesuai `@docs/ARCHITECTURE.md` dan `@docs/API_SPEC.md`.
abstract final class DioClient {
  static Dio create() {
    return Dio(
      BaseOptions(
        connectTimeout: ApiConstants.networkTimeout,
        receiveTimeout: ApiConstants.networkTimeout,
        sendTimeout: ApiConstants.networkTimeout,
        followRedirects: true,
        maxRedirects: 5,
        headers: const <String, String>{
          'Accept': 'application/json',
        },
      ),
    );
  }
}
