/// Hierarki exception aplikasi (pure Dart) dengan pesan yang ramah bagi pembaca buku (`D-013`).
sealed class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Dilempar ketika alamat sinkronisasi belum tersedia.
final class EmptyGasUrlException extends AppException {
  const EmptyGasUrlException([
    super.message =
        'Sambungan rak buku belum siap. Silakan periksa pengaturan aplikasi.',
  ]) : super(code: 'EMPTY_GAS_URL');
}

/// Dilempar ketika koneksi atau respons melewati batas waktu `15 detik` (`F-11`).
final class TimeoutException extends AppException {
  const TimeoutException([
    super.message =
        'Sambungan membutuhkan waktu terlalu lama. Periksa internetmu lalu coba kembali.',
  ]) : super(code: 'TIMEOUT');
}

/// Dilempar ketika perangkat tidak memiliki koneksi jaringan.
final class NetworkException extends AppException {
  const NetworkException([
    super.message =
        'Tidak dapat terhubung ke internet. Pastikan perangkatmu tersambung ke jaringan.',
  ]) : super(code: 'NETWORK_ERROR');
}

/// Dilempar ketika nomor ISBN sudah terdaftar di koleksi (`BR-01`, `F-04`, `DUPLICATE_ISBN`).
final class DuplicateIsbnException extends AppException {
  const DuplicateIsbnException(
    super.message, {
    this.existingBookId,
  }) : super(code: 'DUPLICATE_ISBN');

  final String? existingBookId;
}

/// Dilempar ketika validasi input gagal (`BR-02` judul kosong, `BR-03` nama peminjam kosong, `VALIDATION_ERROR`).
final class ValidationException extends AppException {
  const ValidationException(super.message) : super(code: 'VALIDATION_ERROR');
}

/// Dilempar ketika `id` baris buku tidak ditemukan (`NOT_FOUND`).
final class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'Buku yang kamu cari belum ditemukan di dalam koleksimu.',
  ]) : super(code: 'NOT_FOUND');
}

/// Dilempar ketika terjadi kendala saat menyinkronkan data koleksi.
final class ServerException extends AppException {
  const ServerException([
    super.message =
        'Sedang ada kendala saat memuat rak bukumu. Silakan coba sesaat lagi.',
    String? code = 'INTERNAL_ERROR',
  ]) : super(code: code);
}
