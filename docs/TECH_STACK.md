# Tech Stack

| Fungsi | Pilihan | Alasan | Catatan |
| :--- | :--- | :--- | :--- |
| Bahasa & Framework | Dart + Flutter (Material 3) | Satu codebase modern untuk Android API 26+, performa 60 fps, ekosistem kamera & UI kuat | Rombakan *clean slate* dari `book_apps-dev` |
| State Management & DI | `flutter_riverpod` (`Notifier` / `AsyncNotifier`) | Memisahkan state asinkron GAS App & Google Books API dari widget secara eksplisit dan mudah diuji | Satu provider/notifier per alur/fitur utama |
| Navigasi / Routing | `go_router` | Rute deklaratif untuk transisi antar layar (`Home`, `Scanner`, `Form`, `Detail`, `Settings`) dan passing parameter | Mendukung animasi transisi halus |
| HTTP Client | `dio` | Mendukung konfigurasi `connectTimeout` & `receiveTimeout` 15 detik secara global, interceptor logging, dan penanganan redirect GAS Web App | Wajib mengikuti HTTP 302 redirect dari `script.google.com` |
| Pemindai Barcode Kamera | `mobile_scanner` | Dukungan ML Kit / CameraX ringan untuk format EAN-13 dan ISBN-10 di Android | Batasi format pemindaian ke `BarcodeFormat.ean13` & `ean8` / ISBN relevan agar cepat |
| Penyimpanan Lokal Ringan | `shared_preferences` | Menyimpan konfigurasi URL GAS App, preferensi tema (`light`/`dark`), dan preferensi font (`sans`/`serif`) | Tidak digunakan untuk menyimpan cache database buku |
| Tipografi & Gambar Sampul | `google_fonts` + `cached_network_image` | `google_fonts` menyediakan `Plus Jakarta Sans` dan `Lora`; `cached_network_image` menampilkan `cover_url` dengan fallback error ke *Generated Book Cover* | Hormati fallback sistem bila font gagal diunduh |
| Backend & Penyimpanan Utama | Google Sheets + Google Apps Script (`Code.gs`) | Penyimpanan pribadi gratis dan transparan; kontrak didefinisikan di `@docs/API_SPEC.md` | Pembuatan skrip `Code.gs` dilakukan terpisah di luar repo Flutter |
| Layanan Metadata Eksternal | Google Books API (`volumes`) | Lookup metadata otomatis berdasarkan ISBN tanpa biaya langganan | Endpoint publik `https://www.googleapis.com/books/v1/volumes` |
| Pengujian | `flutter_test` + `mocktail` | Unit test use case/repository, widget test komponen & layar, dan mock HTTP client | Jalankan via `flutter test` |

## Versi
- Gunakan Flutter SDK stabil terbaru yang terpasang di lingkungan pengembang dengan target Android `minSdkVersion = 26` (Android 8.0).
- Seluruh paket pub.dev menggunakan versi stabil terbaru yang kompatibel saat Phase 0 dan dikunci di `pubspec.lock`.

## Dependensi yang dilarang / dihindari
- **Dilarang memakai `get` / GetX** atau **`get_it`** (menggantikan pola lama di `book_apps-dev`; seluruh state dan DI terpusat di `flutter_riverpod`).
- **Dilarang memakai `sqflite`, `hive`, atau `isar`** karena MVP tidak menyimpan database koleksi secara lokal.
- **Dilarang memakai paket ikon multi-warna**; gunakan ikon garis monokrom (`Icons.*_outlined` atau SVG monokrom).

## Aturan menambah dependensi
Catat alasan penambahan paket baru di `@docs/DECISIONS.md` sebelum mengubah `pubspec.yaml`; utamakan paket yang sudah tercantum pada tabel di atas.