# Rencana Pengerjaan

Status: `- [ ]` belum, `- [x]` selesai. Kerjakan berurutan satu task sekali waktu; jangan mulai fase berikutnya sebelum gerbang fase lulus.

## Phase 0: Setup dan fondasi
### T-001 Reset proyek & konfigurasi dependensi Flutter Android
- Tujuan: Membersihkan struktur lama `book_apps-dev` (*clean slate*), menyetel `minSdk = 26` dan orientasi `portrait` di `AndroidManifest.xml`, serta memasang dependensi inti (`flutter_riverpod`, `go_router`, `dio`, `mobile_scanner`, `shared_preferences`, `google_fonts`, `cached_network_image`, `mocktail`).
- Menyentuh: `pubspec.yaml`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `lib/`
- Dependensi: -
- Selesai jika: `flutter pub get` sukses, folder `lib/` lama bersih, dan kerangka dasar berjalan tanpa error.
- Verifikasi: `flutter analyze && flutter test`
- [x] Selesai

### T-002 Token desain, tema Terang/Gelap & peralihan tipografi
- Tujuan: Mengimplementasikan token warna, spasi, radius, dan tema Material 3 (Light & Dark) serta dukungan ganti font *Plus Jakarta Sans* (`sans`) dan *Lora* (`serif`) sesuai `@docs/DESIGN_SYSTEM.md`.
- Menyentuh: `lib/core/theme/app_colors.dart`, `lib/core/theme/app_typography.dart`, `lib/core/theme/app_tokens.dart`, `lib/core/theme/app_theme.dart`, `lib/core/config/app_preferences.dart`
- Dependensi: T-001
- Selesai jika: `AppTheme.light` dan `AppTheme.dark` mendukung kedua tipe font dan lolos widget test pergantian tema/font.
- Verifikasi: `flutter test test/core/theme`
- [x] Selesai

### T-003 Utilitas bisnis inti & komponen atomik/molekul reusable
- Tujuan: Membuat helper `GreetingHelper` (`BR-04`), `IsbnNormalizer` (`BR-01`), serta widget `GeneratedBookCover` (`BR-05`), `BookCoverView`, `StatusBadge`, `ErrorRetryView`, dan `FloatingBottomNav` (label di bawah ikon hanya saat aktif).
- Menyentuh: `lib/core/utils/greeting_helper.dart`, `lib/core/utils/isbn_normalizer.dart`, `lib/core/widgets/*.dart`
- Dependensi: T-002
- Selesai jika: Unit test sapaan waktu (4 rentang jam) dan normalisasi ISBN lulus; widget test `GeneratedBookCover` dan `FloatingBottomNav` lulus.
- Verifikasi: `flutter test test/core`
- [x] Selesai

### T-004 Layer domain & data (Kontrak GAS App & Google Books API)
- Tujuan: Membuat entitas `Book`, `ReadingStatus`, use case `CheckDuplicateIsbn`, `DioClient` (timeout 15 detik), `GasBookDataSource` (`list`, `create`, `update`, `delete`), `GoogleBooksDataSource`, dan `BookRepositoryImpl` beserta `ErrorMapper`.
- Menyentuh: `lib/core/network/dio_client.dart`, `lib/core/error/*.dart`, `lib/features/books/domain/**`, `lib/features/books/data/**`
- Dependensi: T-003
- Selesai jika: Unit test parsing JSON GAS App (termasuk handling redirect/error/timeout 15s) dan Google Books API lulus 100% menggunakan `mocktail`.
- Verifikasi: `flutter test test/features/books/domain test/features/books/data`
- [x] Selesai

**Gerbang Phase 0:** `flutter analyze` bersih dan seluruh unit/widget test fondasi lulus.

---

## Phase 1: MVP Inti — Koleksi, Scan ISBN, & Input Manual
### T-005 Layar Setelan (`SettingsPage`) & konfigurasi otomatis URL GAS App
- Fitur: F-13
- Tujuan: Membangun `settingsProvider` (dengan URL deployment GAS App bawaan `ApiConstants.defaultGasWebAppUrl` tanpa perlu input manual) dan `SettingsPage` untuk mengganti tema Terang/Gelap serta tipografi *Sans-Serif* / *Serif Buku*.
- Menyentuh: `lib/features/settings/presentation/**`, `lib/core/router/app_router.dart`, `lib/app.dart`
- Dependensi: T-004
- Selesai jika: URL GAS bawaan terkonfigurasi otomatis serta perubahan tema dan font tersimpan di `SharedPreferences` dan langsung memengaruhi tampilan aplikasi.
- Verifikasi: `flutter test test/features/settings`
- [x] Selesai

### T-006 Layar Beranda (`HomePage`), Pencarian & Filter Koleksi
- Fitur: F-01, F-06, F-11, F-12
- Tujuan: Membangun `booksProvider`, `HomePage` dengan sapaan waktu dinamis, `HeroScanCard` (CTA **Scan Barcode ISBN** & **Ke Koleksi**), ringkasan statistik, pencarian teks, filter chips, daftar `BookListCard`, state loading/empty/error + tombol **Coba Lagi**, dan `FloatingBottomNav`.
- Menyentuh: `lib/features/books/presentation/providers/books_provider.dart`, `lib/features/books/presentation/pages/home_page.dart`, `lib/features/books/presentation/widgets/*.dart`
- Dependensi: T-005
- Selesai jika: Daftar buku ter-render dengan `BookCoverView` (fallback `GeneratedBookCover`), pencarian/filter berfungsi, dan state error menampilkan tombol **Coba Lagi**.
- Verifikasi: `flutter test test/features/books/presentation/home_page_test.dart`
- [x] Selesai

### T-007 Layar Pemindai Barcode ISBN (`ScannerPage`) & Deteksi Duplikat
- Fitur: F-02, F-03, F-04
- Tujuan: Mengintegrasikan `mobile_scanner` pada `ScannerPage`, menjalankan pengecekan duplikat ISBN (`BR-01`) sebelum lookup Google Books API, menampilkan peringatan + tautan ke detail jika duplikat, atau opsi **Isi Manual** jika tidak ditemukan.
- Menyentuh: `lib/features/books/presentation/providers/isbn_lookup_provider.dart`, `lib/features/books/presentation/pages/scanner_page.dart`
- Dependensi: T-006
- Selesai jika: Skenario ISBN baru ketemu, ISBN duplikat terblokir, dan ISBN tidak ketemu terverifikasi lewat test.
- Verifikasi: `flutter test test/features/books/presentation/scanner_page_test.dart`
- [x] Selesai

### T-008 Formulir Tambah & Sunting Metadata Buku (`BookFormPage`)
- Fitur: F-03, F-05, F-06, F-08
- Tujuan: Membangun `BookFormPage` untuk input baru (hasil *autofill* maupun manual) dan sunting metadata (`isbn`, `title`, `authors`, `reading_status`, `notes`) dengan pratinjau sampul dinamis (*cover_url* atau *Generated Book Cover* real-time) dan validasi field wajib (`BR-02`).
- Menyentuh: `lib/features/books/presentation/pages/book_form_page.dart`
- Dependensi: T-007
- Selesai jika: Formulir menolak judul kosong, merender *Generated Book Cover* secara live saat input manual, dan mengirim `create`/`update` ke `booksProvider`.
- Verifikasi: `flutter test test/features/books/presentation/book_form_page_test.dart`
- [x] Selesai

**Gerbang Phase 1:** Alur *Home -> Scan/Manual -> Autofill/Fallback -> Simpan ke GAS App* berjalan mulus dan lulus seluruh widget/unit test.

---

## Phase 2: Detail Buku, Peminjaman Teman & Penghapusan
### T-009 Layar Detail Buku (`BookDetailPage`), Popup Peminjaman & Hapus Buku
- Fitur: F-07, F-08, F-09, F-10, F-11
- Tujuan: Membangun `BookDetailPage` dengan sampul besar, tabel metadata, tombol **Catat Dipinjam Teman** yang membuka `BorrowModalSheet` (`borrower_name`, `borrowed_at`), tombol **Tandai Sudah Dikembalikan** (`BR-03`), tombol **Edit Data & Status Baca Buku**, dan tombol **Hapus Buku** dengan dialog konfirmasi.
- Menyentuh: `lib/features/books/presentation/pages/book_detail_page.dart`, `lib/features/books/presentation/widgets/borrow_modal_sheet.dart`
- Dependensi: T-008
- Selesai jika: Peminjaman via popup, pengembalian (mengosongkan nama & tanggal pinjam), navigasi edit metadata, dan hapus buku terverifikasi oleh widget test.
- Verifikasi: `flutter test test/features/books/presentation/book_detail_page_test.dart`
- [x] Selesai

### T-010 Uji Integrasi End-to-End & Build APK Release/Debug
- Fitur: F-01 s.d. F-13
- Tujuan: Menulis tes integrasi alur penuh aplikasi (CRUD + duplikat ISBN + pinjam/kembali + ganti tema/font) dan memastikan build APK Android berhasil tanpa error.
- Menyentuh: `test/integration/app_flow_test.dart`
- Dependensi: T-009
- Selesai jika: Seluruh test suite lulus (`flutter test`), `flutter analyze` bersih, dan `flutter build apk --debug` sukses.
- Verifikasi: `flutter analyze && flutter test`
- [x] Selesai

**Gerbang Phase 2 (Rilis MVP v1.0):** Seluruh kriteria penerimaan (`AC-01` s.d. `AC-06`) terverifikasi dan APK siap diuji bersama deployment GAS App.

---

## Backlog (Pasca-MVP v1.1)
- Fitur **Wishlist Buku** (Sheet `Wishlist` terpisah + layar daftar incaran + aksi *Pindahkan ke Koleksi*).
- Dukungan platform Web, iOS, dan Desktop.
- Cache lokal / antrean sinkronisasi *offline*.
- Riwayat log peminjaman per buku dan multi-eksemplar (*copies*).