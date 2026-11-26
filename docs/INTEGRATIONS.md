# Integrasi Pihak Ketiga

| Layanan | Fungsi | Fitur | Mode | Tempat menyimpan kunci / URL |
| :--- | :--- | :--- | :--- | :--- |
| Google Apps Script Web App (`Code.gs`) | Backend CRUD ke Google Sheets (`Books`) | `F-01`, `F-04`, `F-05`, `F-08`, `F-09`, `F-10` | Produksi pribadi | `SharedPreferences` (`gas_web_app_url`) diatur via layar Setelan |
| Google Books API | Lookup metadata buku & `cover_url` dari nomor ISBN | `F-03` | Produksi publik (tanpa API key) | Tidak memakai kunci rahasia (`[ASUMSI] A-03`) |
| Android CameraX / ML Kit (via `mobile_scanner`) | Pemindaian barcode ISBN-13 / ISBN-10 secara lokal di perangkat | `F-02` | On-device | Tidak memerlukan kunci API |

---

## 1. Google Apps Script Web App (`GAS App`)
- **Alur:**
  1. Pengguna menempelkan URL deployment Web App (`https://script.google.com/macros/s/.../exec`) di layar **Setelan**.
  2. Aplikasi memanggil `GET ?action=list` saat memuat koleksi di `HomePage`, dan `POST` JSON untuk `create`, `update`, `delete`.
  3. `Dio` mengikuti HTTP `302` redirect bawaan Google Apps Script untuk membaca body JSON respons.
- **Titik sentuh di kode:** `lib/features/books/data/datasources/gas_book_datasource.dart`
- **Penanganan gagal:**
  - Jika `gas_web_app_url` kosong: jangan kirim HTTP request; tampilkan prompt di `HomePage` untuk mengisi URL di `SettingsPage`.
  - Jika timeout (`> 15 detik`) atau galat jaringan/server: lempar `AppException` dan tampilkan pesan galat + tombol **Coba Lagi** (`F-11`).
- **Batasan:** Latensi *cold start* Google Apps Script (1–4 detik) dan kuota eksekusi harian Google Apps Script (sangat cukup untuk penggunaan tunggal).

## 2. Google Books API (& Fallback OpenLibrary Books API)
- **Alur:**
  1. Setelah barcode ISBN terbaca dan lolos pengecekan duplikat (`F-04`), aplikasi memanggil:
     `GET https://www.googleapis.com/books/v1/volumes?q=isbn:<NORMALIZED_ISBN>&key=<GOOGLE_BOOKS_API_KEY>`
     (Kunci API disimpan secara aman di `lib/core/config/app_secrets.local.dart` yang di-gitignore atau disuplai lewat `--dart-define=GOOGLE_BOOKS_API_KEY=...` sesuai `D-011`).
  2. Jika `totalItems > 0`, ambil elemen pertama `items[0].volumeInfo`:
     - `title` -> `title`
     - `authors` (array) -> digabung dengan `", "`
     - `publisher` -> `publisher`
     - `publishedDate` -> ambil 4 digit tahun pertama (`YYYY`)
     - `imageLinks.thumbnail` atau `smallThumbnail` -> konversi awalan `http://` menjadi `https://` agar tidak diblokir *cleartext traffic* Android.
  3. **Fallback Otomatis Saat Kuota Habis (`HTTP 429 / 403`) atau `totalItems == 0`:**
     - Aplikasi secara otomatis memanggil `GET https://openlibrary.org/api/books?bibkeys=ISBN:<NORMALIZED_ISBN>&format=json&jscmd=data` untuk mengekstrak `title`, `authors`, `publishers`, `publish_date` (`YYYY`), dan `cover.medium` (`https://`).
  4. Jika di kedua sumber tetap tidak ditemukan, kembalikan hasil kosong (`null`) agar UI menampilkan opsi **Isi Manual Sekarang** dengan membawa nomor ISBN (`F-05`).
- **Titik sentuh di kode:** `lib/features/books/data/datasources/google_books_datasource.dart`
- **Penanganan gagal:** Jika API timeout (`> 15 detik`) atau gagal diakses, pengguna tetap dapat menekan **Isi Manual** dengan nomor ISBN yang sudah terbaca (`F-05`).
- **Batasan:** Buku terbitan indie/lokal lama sering tidak memiliki entri atau `imageLinks` di Google Books; ditangani oleh *Generated Book Cover* (`F-06`).