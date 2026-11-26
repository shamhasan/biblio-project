import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/isbn_normalizer.dart';
import '../../domain/entities/book.dart';
import '../../domain/usecases/check_duplicate_isbn.dart';
import 'books_provider.dart';

/// Provider untuk use case [CheckDuplicateIsbn] (`BR-01`, `F-04`).
final checkDuplicateIsbnProvider = Provider<CheckDuplicateIsbn>((ref) {
  return const CheckDuplicateIsbn();
});

/// Hierarki state untuk alur pemindaian ISBN dan pencarian informasi buku (`T-007`).
sealed class IsbnLookupState {
  const IsbnLookupState();
}

/// State awal menunggu kamera memindai kode batang ISBN.
final class IsbnLookupIdle extends IsbnLookupState {
  const IsbnLookupIdle();
}

/// State ketika informasi buku sedang dicari berdasarkan ISBN (`F-03`).
final class IsbnLookupLoading extends IsbnLookupState {
  const IsbnLookupLoading(this.normalizedIsbn);

  final String normalizedIsbn;
}

/// State ketika ISBN yang dipindai sudah ada di dalam rak koleksi (`BR-01`, `F-04`).
final class IsbnLookupDuplicate extends IsbnLookupState {
  const IsbnLookupDuplicate({
    required this.normalizedIsbn,
    required this.existingBook,
  });

  final String normalizedIsbn;
  final Book existingBook;
}

/// State ketika informasi buku berhasil ditemukan (`F-03`).
final class IsbnLookupFound extends IsbnLookupState {
  const IsbnLookupFound({
    required this.normalizedIsbn,
    required this.metadata,
  });

  final String normalizedIsbn;
  final BookMetadata metadata;
}

/// State ketika informasi buku belum ditemukan secara otomatis sehingga pengguna
/// diarahkan untuk melengkapi judul & penulis secara manual (`F-05`, `F-11`).
final class IsbnLookupNotFound extends IsbnLookupState {
  const IsbnLookupNotFound({
    required this.normalizedIsbn,
    required this.message,
  });

  final String normalizedIsbn;
  final String message;
}

/// Notifier yang mengelola deteksi kode batang ISBN, pengecekan buku ganda (`BR-01`),
/// dan pencarian detail buku (`F-02`, `F-03`, `F-04`, `F-05`).
class IsbnLookupNotifier extends Notifier<IsbnLookupState> {
  @override
  IsbnLookupState build() => const IsbnLookupIdle();

  /// Memproses string kode batang mentah dari kamera atau input ISBN.
  Future<void> onBarcodeDetected(String rawBarcode) async {
    if (state is IsbnLookupLoading) {
      return;
    }

    final normalized = IsbnNormalizer.normalize(rawBarcode);
    if (!IsbnNormalizer.isValid(normalized)) {
      return;
    }

    final currentState = state;
    if (currentState is IsbnLookupDuplicate &&
        currentState.normalizedIsbn == normalized) {
      return;
    }
    if (currentState is IsbnLookupNotFound &&
        currentState.normalizedIsbn == normalized) {
      return;
    }

    // 1. Cek apakah buku sudah ada di rak koleksi (BR-01, F-04)
    final currentBooks = ref.read(booksProvider).valueOrNull ?? const <Book>[];
    final checkDuplicate = ref.read(checkDuplicateIsbnProvider);
    final duplicateBook = checkDuplicate(
      rawIsbn: normalized,
      existingBooks: currentBooks,
    );

    if (duplicateBook != null) {
      state = IsbnLookupDuplicate(
        normalizedIsbn: normalized,
        existingBook: duplicateBook,
      );
      return;
    }

    // 2. Jika belum ada di rak, cari informasi buku dari katalog online (F-03)
    state = IsbnLookupLoading(normalized);

    try {
      final repository = ref.read(bookRepositoryProvider);
      final metadata = await repository.lookupBookByIsbn(normalized);

      if (metadata != null) {
        state = IsbnLookupFound(
          normalizedIsbn: normalized,
          metadata: metadata,
        );
      } else {
        state = IsbnLookupNotFound(
          normalizedIsbn: normalized,
          message:
              'Jangan khawatir, nomor ISBN $normalized sudah tersimpan. Yuk, lengkapi judul dan penulisnya secara manual.',
        );
      }
    } catch (error) {
      final errMessage = error is AppException
          ? '${error.message} Nomor ISBN $normalized tetap dibawa ke formulir manual.'
          : 'Belum dapat memuat detail otomatis. Nomor ISBN $normalized tetap dibawa ke formulir manual.';

      state = IsbnLookupNotFound(
        normalizedIsbn: normalized,
        message: errMessage,
      );
    }
  }

  /// Mengatur ulang state pemindaian ke `IsbnLookupIdle`.
  void reset() {
    state = const IsbnLookupIdle();
  }
}

final isbnLookupProvider =
    NotifierProvider<IsbnLookupNotifier, IsbnLookupState>(
  IsbnLookupNotifier.new,
);
