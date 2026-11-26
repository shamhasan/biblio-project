# Aplikasi Manajemen Buku Mandiri (Android MVP)

Aplikasi seluler Android berbasis Flutter untuk mengelola koleksi buku pribadi secara mandiri menggunakan Google Sheets (via Google Apps Script Web App) sebagai basis data utama serta pemindai barcode ISBN kamera dan Google Books API untuk *autofill* metadata. Proyek ini adalah rombakan *clean slate* dari `book_apps-dev` dengan target rilis MVP `2026-11-29`.

## Tech stack
- Framework: Flutter (Material 3, Dart, Android `minSdk = 26`, orientasi Portrait)
- State Management & DI: `flutter_riverpod` (`Notifier` / `AsyncNotifier`)
- Routing: `go_router`
- Networking & Scanner: `dio` (timeout `15s`, follow redirect GAS), `mobile_scanner`
- Penyimpanan Lokal & UI: `shared_preferences` (URL GAS, tema, font), `google_fonts` (`Plus Jakarta Sans` & `Lora`), `cached_network_image`
- Backend: Google Sheets (`Books`) via Google Apps Script (`Code.gs`, disiapkan terpisah)
Detail dan alasan: @docs/TECH_STACK.md

## Perintah
- Install: `flutter pub get`
- Jalankan: `flutter run`
- Test: `flutter test`
- Lint/format: `flutter analyze && dart format --output=none --set-exit-if-changed .`
- Build: `flutter build apk --debug`

## Struktur folder
```text
lib/
├── main.dart, app.dart         # Entry point, ProviderScope, MaterialApp.router
├── core/                       # Config, constants, error, dio, router, theme, utils, reusable widgets
└── features/
    ├── books/                  # Clean Architecture by-feature (data / domain / presentation)
    └── settings/               # Pengaturan URL GAS App, tema Terang/Gelap, tipografi Sans/Serif
test/                           # Unit test, widget test, dan integration test
```
Penjelasan arsitektur lengkap: @docs/ARCHITECTURE.md

## Konvensi inti
- **Pemisahan layer ketat:** `presentation` tidak boleh mengimpor `data` atau `dio`; `domain` harus pure Dart tanpa `package:flutter/material.dart`.
- **Token desain wajib:** Gunakan token warna, tipografi, dan spasi di `lib/core/theme/`; dilarang hardcode hex warna atau ukuran font di widget fitur (@docs/DESIGN_SYSTEM.md).
- **Ikon monokrom:** Gunakan hanya ikon garis monokrom (`Icons.*_outlined`); dilarang memakai emoji atau ikon multi-warna.
- **Aturan bisnis kunci:** Normalisasi ISBN sebelum cek duplikat (`BR-01`); kosongkan `borrower_name` dan `borrowed_at` saat buku dikembalikan (`BR-03`); fallback otomatis ke `GeneratedBookCover` bila `cover_url` kosong/gagal muat (`BR-05`).
- **Navigasi bawah:** Label diletakkan di bawah ikon dan hanya tampil pada tab yang sedang aktif.
Selengkapnya: @docs/CONVENTIONS.md

## Jangan
- Jangan mempertahankan atau menyalin arsitektur lama `book_apps-dev` (dilarang memakai GetX/`get_it`/SQLite/Hive).
- Jangan menaruh logika bisnis atau panggilan HTTP di dalam widget UI.
- Jangan meng-hardcode URL deployment GAS App permanen di kode sumber; baca dari `SharedPreferences`.
- Jangan mengerjakan fitur di luar cakupan MVP (seperti Wishlist) sebelum seluruh phase selesai (@docs/PRD.md).

## Cara bekerja
1. Baca dokumen yang relevan sebelum menulis kode: @docs/PRD.md, @docs/TASKS.md, dan dokumen teknis terkait.
2. Kerjakan satu task sekali waktu sesuai urutan di @docs/TASKS.md; jangan lompat fase sebelum gerbang fase lulus.
3. Jalankan perintah verifikasi task (`flutter analyze` dan `flutter test`); jangan menandai selesai sebelum lulus.
4. Centang task di @docs/TASKS.md (`- [x]`); catat keputusan teknis baru di @docs/DECISIONS.md.
5. Bila ada hal yang tidak jelas atau butuh penyesuaian kontrak, catat di @docs/OPEN_QUESTIONS.md dan tanya user. Jangan menebak.

## Peta dokumen
- @docs/PRD.md — Spesifikasi kebutuhan produk, fitur `F-01` s.d. `F-13`, dan acceptance criteria
- @docs/TECH_STACK.md — Daftar paket, versi target, dan dependensi yang dilarang
- @docs/ARCHITECTURE.md — Layer Clean Architecture, struktur folder, state, dan aliran data
- @docs/DATA_MODEL.md — Skema sheet `Books`, aturan validasi data, dan kunci `SharedPreferences`
- @docs/API_SPEC.md — Kontrak JSON endpoint Google Apps Script (`list`, `create`, `update`, `delete`)
- @docs/INTEGRATIONS.md — Alur integrasi GAS App, Google Books API, dan `mobile_scanner`
- @docs/SCREENS.md — Peta navigasi, state layar, dan interaksi pengguna
- @docs/DESIGN_SYSTEM.md — Palet Terang/Gelap, tipografi *Sans-Serif*/*Serif*, dan spesifikasi komponen UI
- @docs/CONVENTIONS.md — Standar penamaan, aturan import antar layer, dan konvensi Git
- @docs/TESTING.md — Strategi unit/widget/integration test dan gerbang kualitas
- @docs/TASKS.md — Daftar task atomik bertahap (`Phase 0` s.d. `Phase 2`)
- @docs/DECISIONS.md — Log keputusan produk dan teknis
- @docs/OPEN_QUESTIONS.md — Daftar pertanyaan terbuka dan asumsi aktif