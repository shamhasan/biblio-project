# Layar dan Alur

## Peta navigasi
```text
                  ┌──────────────────────────────────────┐
                  │           HomePage (/)               │
                  │  - Sapaan Pagi/Siang/Sore/Malam      │
                  │  - Hero Card (Scan ISBN | Ke Koleksi)│
                  │  - Statistik + Search + Filter       │
                  │  - Daftar BookListCard               │
                  └───┬──────────┬──────────┬─────────┬──┘
                      │          │          │         │
        (CTA Scan /   │   (Input │  (Tap    │  (Tab / │
         Tab Scan)    │  Manual) │  Kartu)  │  Ikon)  │
                      ▼          │          ▼         ▼
             ┌────────────────┐  │  ┌──────────────┐ ┌──────────────┐
             │  ScannerPage   │  │  │BookDetailPage│ │ SettingsPage │
             │   (/scanner)   │  │  │ (/book/:id)  │ │ (/settings)  │
             └───┬─────────┬──┘  │  └───┬──────┬───┘ └──────────────┘
                 │         │     │      │      │
    (ISBN Ketemu │   (Tak  │     │ (Edit│ (Pinjam)
     & Unik)     │ Ketemu) │     │ Data)│      │
                 ▼         ▼     ▼      ▼      ▼
             ┌───────────────────────┐  ┌──────────────────┐
             │     BookFormPage      │  │BorrowModalSheet  │
             │     (/book/form)      │  │ (Bottom Sheet)   │
             └───────────────────────┘  └──────────────────┘
```

## Layar

### 1. `HomePage`
- **Fitur:** `F-01`, `F-02`, `F-05`, `F-06`, `F-11`, `F-12` · **Rute:** `/`
- **Tujuan:** Pusat navigasi koleksi buku pribadi, ringkasan statistik, pencarian/penyaringan, dan akses cepat ke pemindai ISBN.
- **Komponen utama:**
  - `DynamicGreetingHeader`: Sapaan waktu (`Selamat Pagi/Siang/Sore/Malam`) + judul layar + tombol ikon monokrom ke `SettingsPage`.
  - `HeroScanCard`: Kartu utama dengan CTA **Scan Barcode ISBN** (`/scanner`) dan CTA sekunder **Ke Koleksi** (scroll halus ke daftar buku) + tombol kecil **+ Input Manual** (`/book/form`).
  - `CollectionSummaryRow`: 3 kartu ringkas (*Total Buku*, *Dibaca*, *Dipinjam*).
  - `SearchInput` & `FilterChipRow` (*Semua*, *Sedang Dibaca*, *Selesai*, *Dipinjam Teman*).
  - `BookListCard`: Sampul (`BookCoverView`), judul, penulis, badge status baca & badge status pinjam.
  - `FloatingBottomNav`: 3 tab (*Koleksi*, *Scan*, *Setelan*) dengan label di bawah ikon yang hanya tampil pada tab aktif.
- **Data yang ditampilkan/diambil:** `GET ?action=list` dari GAS App via `booksProvider`.
- **State:**
  - *Loading:* Skeleton/indikator muat terpusat.
  - *Kosong (Belum ada URL GAS):* Banner panduan mengatur URL GAS di Setelan.
  - *Kosong (0 buku):* Ilustrasi garis monokrom + tombol Scan ISBN / Input Manual.
  - *Error:* `ErrorRetryView` dengan pesan galat dan tombol **Coba Lagi**.
  - *Sukses:* Daftar kartu buku yang dapat dicari dan disaring.
- **Aksi dan hasilnya:** Tap **Scan Barcode ISBN** -> `/scanner`; Tap **+ Input Manual** -> `/book/form` (kosong); Tap `BookListCard` -> `/book/:id`.
- **Referensi desain:** `design/app-screens-mockup.html` (Layar 1).

### 2. `ScannerPage`
- **Fitur:** `F-02`, `F-03`, `F-04`, `F-05`, `F-11` · **Rute:** `/scanner`
- **Tujuan:** Memindai barcode ISBN menggunakan kamera belakang dan memvalidasi duplikasi sebelum mengisi formulir.
- **Komponen utama:** `MobileScanner` viewfinder dengan bingkai target & animasi garis pindai halus (`2s` loop, nonaktif saat *Reduce Motion*), status pemindaian, dan tombol fallback **Isi Manual**.
- **Data yang ditampilkan/diambil:** Cek duplikat lokal terhadap `booksProvider` (`BR-01`) lalu `GET` ke Google Books API (`F-03`).
- **State:**
  - *Scanning:* Kamera aktif menunggu deteksi barcode.
  - *Lookup Loading:* Overlay indikator *"Mencari metadata ISBN..."*.
  - *Duplikat ISBN:* Banner peringatan *"Buku dengan ISBN ini sudah terdaftar"* + tombol **Lihat Detail Buku** (`/book/:existingId`).
  - *Tidak Ditemukan / Error API:* Banner informasi + tombol **Isi Manual Sekarang** (`/book/form` membawa `isbn`).
  - *Izin Kamera Ditolak:* Pesan izin kamera + tombol **Buka Pengaturan** & **Input Manual**.
- **Referensi desain:** `design/app-screens-mockup.html` (Layar 2).

### 3. `BookFormPage`
- **Fitur:** `F-03`, `F-05`, `F-06`, `F-08`, `F-11` · **Rute:** `/book/form`
- **Tujuan:** Menambah buku baru (dari hasil *autofill* ISBN maupun input manual) atau menyunting metadata & status baca buku yang sudah ada.
- **Komponen utama:**
  - `BookCoverView` (pratinjau langsung: menampilkan gambar `cover_url` bila ada, atau memperbarui *Generated Book Cover* secara real-time saat `title` / `authors` diketik).
  - Input field: `ISBN` (opsional), `Judul Buku` (wajib), `Penulis` (opsional), dropdown `Status Baca` (*Belum Dibaca*, *Sedang Dibaca*, *Selesai*), dan `Catatan Pribadi` (opsional).
  - Tombol **Simpan Metadata Buku**.
- **Data yang ditampilkan/diambil:** Mengirim `POST action: "create"` atau `POST action: "update"` ke GAS App.
- **State:** *Idle/Edit*, *Submitting* (tombol disabled + loading spinner), *Validation Error* (judul kosong), *Network Error* (`SnackBar` + tetap di form agar input tidak hilang).
- **Referensi desain:** `design/app-screens-mockup.html` (Layar 3).

### 4. `BookDetailPage` & `BorrowModalSheet`
- **Fitur:** `F-07`, `F-08`, `F-09`, `F-10`, `F-11` · **Rute:** `/book/:id`
- **Tujuan:** Menampilkan detail lengkap buku dan memisahkan aksi peminjaman teman dari penyuntingan metadata buku.
- **Komponen utama:**
  - Hero sampul ukuran besar (`BookCoverView`), judul, penulis, `StatusBadge` baca dan pinjam.
  - Kartu tabel metadata (`ISBN`, `Penerbit / Tahun`, `Ketersediaan`, `Catatan`).
  - Tombol aksi terpisah:
    1. **Catat Dipinjam Teman** / **Ubah Info Peminjam** -> membuka `BorrowModalSheet` (field: `Nama Peminjam` wajib, `Tanggal Pinjam` default hari ini).
    2. **Tandai Sudah Dikembalikan** (muncul hanya saat `is_borrowed == true`) -> menjalankan `BR-03` dan `POST update`.
    3. **Edit Data & Status Baca Buku** -> navigasi ke `/book/form` dengan data buku saat ini.
    4. **Hapus Buku** -> dialog konfirmasi -> `POST delete` -> kembali ke `/`.
- **Referensi desain:** `design/app-screens-mockup.html` (Layar 4).

### 5. `SettingsPage`
- **Fitur:** `F-13` · **Rute:** `/settings`
- **Tujuan:** Mengelola konfigurasi URL GAS App, tema tampilan (Terang/Gelap), dan jenis huruf (*Sans-Serif* / *Serif Buku*).
- **Komponen utama:**
  - Input URL Deployment GAS App + tombol **Simpan & Uji Koneksi**.
  - Pilihan Tema: *Mode Terang* vs *Mode Gelap*.
  - Pilihan Tipografi: *Sans-Serif (Plus Jakarta Sans)* vs *Serif Buku (Lora)*.
- **Referensi desain:** `design/app-screens-mockup.html` (Layar 5).