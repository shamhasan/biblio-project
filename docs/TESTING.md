# Strategi Pengujian

| Level | Yang diuji | Alat | Lokasi file | Perintah |
| :--- | :--- | :--- | :--- | :--- |
| Unit Test | Normalisasi ISBN (`BR-01`), deteksi duplikat, sapaan waktu (`BR-04`), reset data pinjaman (`BR-03`), mapping JSON `BookModel`, dan repository dengan mock `Dio` | `flutter_test`, `mocktail` | `test/core/`, `test/features/books/domain/`, `test/features/books/data/` | `flutter test test/core test/features/books/domain test/features/books/data` |
| Widget Test | Render `GeneratedBookCover` vs `cover_url` (`BR-05`), `FloatingBottomNav` (label hanya saat aktif), validasi form wajib (`BR-02`), `BorrowModalSheet`, dan `ErrorRetryView` | `flutter_test` | `test/core/widgets/`, `test/features/books/presentation/` | `flutter test test/core/widgets test/features/books/presentation` |
| Integrasi / Alur UI | Alur *Home -> Scan/Manual -> Form -> Detail -> Borrow/Return -> Delete* dengan fake `BookRepository` | `flutter_test` | `test/integration/` | `flutter test test/integration` |

## Aturan
- Setiap task fitur pada `@docs/TASKS.md` wajib menyertakan minimal satu unit test atau widget test yang memverifikasi *Acceptance Criteria*-nya.
- **Target cakupan:** Minimal `80%` pada layer `domain` dan `core/utils` (aturan bisnis `BR-01` s.d. `BR-05`).
- **Mock / Fake:** Panggilan HTTP ke GAS App dan Google Books API **wajib di-mock** menggunakan `mocktail` pada pengujian otomatis; jangan memukul endpoint Google Sheets produksi saat menjalankan `flutter test`.

## Gerbang Kualitas (Sebelum Selesai Task)
Setiap task dianggap lulus hanya apabila kedua perintah berikut berhasil tanpa galat:
1. `flutter analyze` (0 errors, 0 warnings)
2. `flutter test` (seluruh test hijau)