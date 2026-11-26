# Konvensi

## Penamaan
- **File & Folder Dart:** `snake_case` (contoh: `book_detail_page.dart`, `generated_book_cover.dart`, `gas_book_datasource.dart`).
- **Kelas, Enum, Typedef:** `UpperCamelCase` (contoh: `BookRepositoryImpl`, `ReadingStatus`, `BorrowModalSheet`).
- **Variabel, Fungsi, Parameter, Provider:** `lowerCamelCase` (contoh: `booksProvider`, `normalizeIsbn`, `borrowBook`).
- **Rute `go_router`:** `kebab-case` / path standar (`/`, `/scanner`, `/book/form`, `/book/:id`, `/settings`).
- **Field JSON & Kolom Sheet:** `snake_case` persis sesuai `@docs/DATA_MODEL.md` (`reading_status`, `is_borrowed`, `borrower_name`, `borrowed_at`, `cover_url`).

## Gaya kode
- Ikuti aturan `flutter_lints` tanpa warning (`flutter analyze` harus bersih `0 issues`).
- Gunakan `const` constructor di setiap widget statis untuk menjaga performa 60 fps.
- Batasi satu file maksimal ~250–300 baris; pecah widget kompleks menjadi sub-widget terpisah di folder `widgets/`.

## Aturan antar layer
- `presentation` **hanya** boleh mengimpor `domain` dan `core`. Dilarang mengimpor file dari `data/`.
- `domain` **hanya** boleh mengimpor file Dart murni di `domain` atau `core/utils` & `core/error`. Dilarang mengimpor `package:flutter/material.dart` atau `package:dio/dio.dart`.
- `data` mengimplementasikan interface dari `domain` dan melakukan konversi `BookModel` <-> `Book` entity.

## Git
- Format pesan commit: `<tipe>(<scope>): <ringkasan singkat>` (contoh: `feat(scanner): add isbn barcode detection and duplicate check`).
- Tipe yang digunakan: `feat`, `fix`, `refactor`, `style`, `test`, `docs`, `chore`.
- Satu commit per task atomik dari `@docs/TASKS.md`.

## Teks dan lokalisasi
- Bahasa antarmuka utama: **Bahasa Indonesia** sesuai `@docs/PRD.md`.
- Simpan string label statis atau pesan error terpusat di konstanta/mapper agar konsisten antar layar.

## Dokumentasi di kode
- Tambahkan komentar `///` singkat pada kelas publik di `domain` (use case, repository interface) dan helper utilitas (`isbn_normalizer.dart`, `greeting_helper.dart`) untuk menjelaskan aturan bisnis (`BR-01` s.d. `BR-05`).