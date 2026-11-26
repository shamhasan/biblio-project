# Arsitektur

## Pola dan alasan
Aplikasi menggunakan **Clean Architecture ringan berbasis fitur (*feature-first*)** yang dipadukan dengan **Riverpod (`AsyncNotifier` / `Notifier`)**. Pola ini dipilih untuk:
1. Mengisolasi kontrak jaringan (GAS App Web App yang melakukan HTTP redirect dan Google Books API) di layer `data` sehingga perubahan struktur respons API tidak merusak logika bisnis maupun tampilan.
2. Menjaga aturan bisnis penting (normalisasi ISBN, deteksi duplikat, pengosongan field peminjaman saat dikembalikan, sapaan waktu) di layer `domain` agar dapat diuji melalui *unit test* murni tanpa emulator.
3. Menggantikan struktur lama `book_apps-dev` yang mencampur tanggung jawab antar folder.

## Layer dan tanggung jawab
| Layer | Berisi | Boleh bergantung pada | Tidak boleh |
| :--- | :--- | :--- | :--- |
| `presentation` | Pages/Screens, Widgets atomik/molekul/organisme, Riverpod `Notifier`/`AsyncNotifier` UI state | `domain`, `core` | Mengimpor `dio`, parsing JSON mentah, atau memanggil endpoint secara langsung |
| `domain` | Entitas (`Book`, `BookMetadata`), kontrak interface `BookRepository`, Use Cases / aturan bisnis (validasi, normalisasi ISBN, cek duplikat) | Pure Dart (`core` utilitas non-UI) | Mengimpor `package:flutter/...`, `dio`, atau `shared_preferences` |
| `data` | Implementasi `BookRepositoryImpl`, `GasRemoteDataSource`, `GoogleBooksDataSource`, DTO/Model JSON mapping | `domain`, `core`, `dio`, `shared_preferences` | Mengimpor widget Flutter atau state UI |
| `core` | Tema & token desain (`AppTheme`, `AppColors`, `AppTypography`), `AppRouter`, `DioClient`, helper sapaan waktu & normalisasi ISBN, custom exceptions | Paket dasar Flutter/Dart | Bergantung pada fitur spesifik di `features/` |

## Aliran data
```text
[UI Screen / Widget]
       │  (trigger event / watch state)
       ▼
[Riverpod Notifier / AsyncNotifier]
       │  (panggil use case / repository)
       ▼
[Domain: BookRepository Interface & Business Rules]
       │
       ├──► [GoogleBooksDataSource (Dio)] ──► Google Books API (GET volumes?q=isbn:...)
       │
       └──► [GasRemoteDataSource (Dio)]   ──► GAS Web App URL (GET list / POST create|update|delete)
                                                    │
                                                    ▼
                                            [Google Sheets: Books]
```

## Struktur folder
```text
lib/
├── main.dart
├── app.dart                                # Root MaterialApp.router, tema & font watcher
├── core/
│   ├── config/
│   │   └── app_preferences.dart            # Wrapper SharedPreferences (GAS URL, theme, font)
│   ├── constants/
│   │   └── api_constants.dart              # Base URL Google Books, timeout 15s
│   ├── error/
│   │   ├── app_exception.dart              # NetworkException, TimeoutException, DuplicateIsbnException, ValidationException
│   │   └── error_mapper.dart               # Pemetaan DioException -> pesan ramah pengguna
│   ├── network/
│   │   └── dio_client.dart                 # Konfigurasi Dio (timeout 15s, followRedirects)
│   ├── router/
│   │   └── app_router.dart                 # Definisi rute go_router
│   ├── theme/
│   │   ├── app_colors.dart                 # Token warna Light & Dark
│   │   ├── app_typography.dart             # Plus Jakarta Sans & Lora TextTheme
│   │   ├── app_tokens.dart                 # Spasi, radius, durasi animasi
│   │   └── app_theme.dart                  # Pembangun ThemeData lengkap
│   ├── utils/
│   │   ├── greeting_helper.dart            # Sapaan Pagi/Siang/Sore/Malam berbasis jam lokal
│   │   └── isbn_normalizer.dart            # Hapus tanda hubung/spasi & validasi 10/13 digit
│   └── widgets/                            # Komponen reusable lintas fitur (@docs/COMPONENTS.md)
│       ├── generated_book_cover.dart
│       ├── book_cover_view.dart
│       ├── status_badge.dart
│       ├── error_retry_view.dart
│       └── floating_bottom_nav.dart
└── features/
    ├── books/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   ├── gas_book_datasource.dart
    │   │   │   └── google_books_datasource.dart
    │   │   ├── models/
    │   │   │   └── book_model.dart
    │   │   └── repositories/
    │   │       └── book_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   ├── book.dart
    │   │   │   └── reading_status.dart
    │   │   ├── repositories/
    │   │   │   └── book_repository.dart
    │   │   └── usecases/
    │   │       └── check_duplicate_isbn.dart
    │   └── presentation/
    │       ├── providers/
    │       │   ├── books_provider.dart     # State daftar koleksi, search & filter
    │       │   └── isbn_lookup_provider.dart
    │       ├── pages/
    │       │   ├── home_page.dart
    │       │   ├── scanner_page.dart
    │       │   ├── book_form_page.dart
    │       │   └── book_detail_page.dart
    │       └── widgets/
    │           ├── hero_scan_card.dart
    │           ├── collection_summary_row.dart
    │           ├── book_list_card.dart
    │           └── borrow_modal_sheet.dart
    └── settings/
        └── presentation/
            ├── providers/
            │   └── settings_provider.dart  # State themeMode, fontFamily, gasUrl
            └── pages/
                └── settings_page.dart
```

Aturan penempatan file baru:
- Fitur baru ditempatkan di `lib/features/<nama_fitur>/` dengan pembagian `data/`, `domain/`, dan `presentation/`.
- Komponen UI yang dipakai lebih dari satu layar ditempatkan di `lib/core/widgets/`.

## State dan navigasi
- **State Koleksi (`booksProvider`):** `AsyncNotifier<List<Book>>` yang memegang daftar buku dari GAS App di memori selama sesi berjalan. Mutasi (`create`, `update`, `delete`, `borrow`, `returnBook`) memperbarui GAS App terlebih dahulu, lalu menyegarkan/memperbarui state lokal saat sukses.
- **State Pencarian & Filter (`bookFilterProvider`):** State turunan (*computed provider*) yang menyaring `booksProvider` berdasarkan kata kunci (`title`, `authors`, `isbn`) dan filter chip (`all`, `reading`, `finished`, `borrowed`) secara instan di memori.
- **State Pengaturan (`settingsProvider`):** `Notifier<SettingsState>` yang membaca/menulis `themeMode`, `fontType`, dan `gasWebAppUrl` ke `SharedPreferences`.
- **Rute Utama (`go_router`):**
  - `/` -> `HomePage` (dengan bilah navigasi bawah melayang: *Koleksi*, *Scan*, *Setelan*).
  - `/scanner` -> `ScannerPage`.
  - `/book/form` -> `BookFormPage` (menerima `extra` opsional: data `Book` untuk edit atau `BookPrefill` hasil scan ISBN).
  - `/book/:id` -> `BookDetailPage`.
  - `/settings` -> `SettingsPage`.

## Penanganan error dan logging
- Semua error dari `Dio` ditangkap di layer `data` dan dipetakan lewat `ErrorMapper` menjadi subclass `AppException` (`NetworkException`, `TimeoutException`, `ServerException`, `EmptyGasUrlException`).
- `AsyncNotifier` mengekspos `AsyncError` ke UI sehingga layar menampilkan komponen `ErrorRetryView` (pesan jelas + tombol **Coba Lagi**) atau `SnackBar` untuk kegagalan aksi mutasi.
- Gunakan `debugPrint` hanya di mode debug (`kDebugMode`) untuk logging HTTP; jangan mencetak URL sensitif atau data pribadi di release build.

## Dependency injection dan konfigurasi
- Seluruh dependensi (`Dio`, `SharedPreferences`, `GasBookDataSource`, `GoogleBooksDataSource`, `BookRepository`) disediakan melalui Riverpod `Provider` di file provider masing-masing dan di-override pada `ProviderScope` di `main.dart`.
- URL deployment GAS App tidak di-*hardcode* permanen di kode sumber; pengguna dapat mengaturnya melalui layar **Setelan** (dengan nilai default kosong yang menampilkan banner panduan konfigurasi bila belum diisi).

## Contoh irisan vertikal
Alur **Catat Peminjaman Buku (`F-09`)**:
1. Pengguna menekan tombol **Catat Dipinjam Teman** di `BookDetailPage`.
2. `BorrowModalSheet` memvalidasi `borrowerName` (wajib) dan `borrowedAt` (default hari ini).
3. Saat **Simpan Pinjaman** ditekan, UI memanggil `ref.read(booksProvider.notifier).borrowBook(bookId, borrowerName, borrowedAt)`.
4. `BookRepositoryImpl.updateBook(...)` mengirim `POST` JSON (`action: "update"`) via `GasBookDataSource` dengan batas timeout 15 detik.
5. Setelah GAS App mengembalikan status sukses, `booksProvider` memperbarui entitas `Book` di state, menutup modal, dan `BookDetailPage` otomatis menampilkan badge **Dipinjam** serta tombol **Tandai Sudah Dikembalikan**.