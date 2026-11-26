# PRD: Aplikasi Manajemen Buku Mandiri (Android MVP)

| Versi | Tanggal | Penulis | Status | Target Rilis |
| :--- | :--- | :--- | :--- | :--- |
| 1.1 | 2026-11-25 | Tim Produk & Engineering | Approved | 2026-11-29 |

## Ringkasan dan tujuan
Aplikasi Manajemen Buku Mandiri adalah aplikasi seluler berbasis Android yang dirancang untuk membantu pemilik buku mengelola perpustakaan pribadinya secara terstruktur menggunakan Google Sheets melalui Google Apps Script (GAS App) sebagai basis data utama serta Google Books API dan pemindai barcode kamera untuk percepatan input metadata. Versi ini merupakan rombakan menyeluruh (*clean slate*) dari `book_apps-dev`.

- **G-01 — Mempercepat Pencatatan Koleksi Buku:** Mengurangi beban input manual melalui pemindaian barcode ISBN dengan *autofill* formulir dan jalur cadangan (*fallback*) manual yang mulus.
- **G-02 — Memantau Progres Baca & Status Peminjaman Secara Terpisah:** Memastikan status bacaan buku tercatat independen dari status peminjaman kepada teman.
- **G-03 — Menyediakan Penyimpanan Mandiri yang Transparan:** Menyinkronkan seluruh operasi CRUD koleksi buku ke Google Sheets milik pengguna via GAS App dengan penanganan *loading* dan *error* yang jelas.

### Indikator Keberhasilan
| ID | Metrik | Target | Sumber Data |
| :--- | :--- | :--- | :--- |
| M-01 | Durasi Input via Scan ISBN (dari buka kamera hingga tersimpan ke Google Sheets) | `< 10 detik` (koneksi stabil) | DR-01, DR-02 |
| M-02 | Keandalan Alur CRUD Inti (*Create, Read/Search/Filter, Update, Borrow/Return, Delete*) | `100%` skenario pengujian lulus tanpa *crash* / korupsi baris | DR-01 |
| M-03 | Adopsi Migrasi Koleksi Pribadi | `>= 15 buku` terinput dalam 7 hari pertama tanpa sunting manual sheet | DR-01 |

## Pengguna
| Peran | Deskripsi | Kebutuhan utama |
| :--- | :--- | :--- |
| Kolektor & Pembaca Mandiri (Pengguna Tunggal) | Pemilik koleksi buku pribadi dengan perangkat Android (min. Android 8.0 / API 26) | Scan cepat barcode ISBN, fallback input manual dengan sampul otomatis, pantau status baca vs dipinjam teman, pengaturan tema terang/gelap & jenis huruf |

## Fitur
| ID | Fitur | Prioritas | MVP? | Deskripsi singkat |
| :--- | :--- | :--- | :--- | :--- |
| F-01 | Beranda Koleksi & Sapaan Dinamis | Must | Ya | Daftar koleksi buku dari GAS App, sapaan waktu perangkat (*Selamat Pagi/Siang/Sore/Malam*), dan ringkasan statistik (Total, Dibaca, Dipinjam). |
| F-02 | Pemindai Barcode ISBN Kamera | Must | Ya | Akses cepat kamera dari kartu aksi utama *Home* dan bilah navigasi bawah untuk memindai EAN-13 / ISBN-10. |
| F-03 | Lookup Google Books API & Autofill | Must | Ya | Mengambil `title`, `authors`, `publisher`, `published_year`, dan `cover_url` berdasarkan ISBN lalu mengisi otomatis formulir tambah buku beserta pratinjau sampul. |
| F-04 | Pencegahan Duplikat ISBN | Must | Ya | Mengecek nomor ISBN ternormalisasi terhadap koleksi sebelum membuka formulir *autofill*; memblokir duplikat dan mengarahkan ke layar detail buku terkait. |
| F-05 | Input Manual & Fallback | Must | Ya | Formulir tambah buku manual (langsung maupun *fallback* saat ISBN tidak ditemukan/gagal pindai, mempertahankan ISBN yang terbaca). |
| F-06 | Generated Book Cover | Must | Ya | Komponen sampul buku programatis (gradien warna, aksen punggung buku kiri, cincin dekoratif kanan atas, judul, penulis) saat `cover_url` kosong atau gagal dimuat. |
| F-07 | Halaman Detail Buku | Must | Ya | Menampilkan sampul, metadata lengkap, status bacaan, dan status ketersediaan/peminjaman buku. |
| F-08 | Sunting Metadata & Status Baca | Must | Ya | Formulir sunting (`isbn`, `title`, `authors`, `reading_status`, `notes`) yang terpisah dari alur peminjaman. |
| F-09 | Manajemen Peminjaman & Pengembalian Teman | Must | Ya | Mencatat pinjaman via *popup modal* (`borrower_name`, `borrowed_at`) di layar detail serta tombol satu ketukan **Tandai Sudah Dikembalikan** yang mengosongkan data peminjam. |
| F-10 | Hapus Buku | Must | Ya | Menghapus baris buku setelah dialog konfirmasi dan menyinkronkan perintah `delete` ke GAS App. |
| F-11 | Penanganan Loading, Error & Timeout | Must | Ya | Indikator pemuatan, pesan galat informatif saat gagal/timeout 15 detik, dan tombol **Coba Lagi**. |
| F-12 | Pencarian & Penyaringan Koleksi | Should | Ya | Pencarian teks (judul, penulis, ISBN) serta *filter chips* berdasarkan status baca (*Belum Dibaca*, *Sedang Dibaca*, *Selesai*) dan status pinjam (*Dipinjam Teman*). |
| F-13 | Pengaturan Tema, Tipografi & URL GAS | Should | Ya | Konfigurasi URL deployment GAS App, peralihan tema Terang/Gelap, dan peralihan tipografi *Sans-Serif* (*Plus Jakarta Sans*) vs *Serif Buku* (*Lora*). |

## Acceptance criteria per fitur
### F-01 Beranda Koleksi & Sapaan Dinamis
- Given pengguna membuka aplikasi pada pukul 08.30 waktu perangkat dan koneksi aktif, when layar *Home* selesai memuat data dari GAS App, then header menampilkan **"Selamat Pagi"** beserta daftar buku dan ringkasan statistik yang akurat.
- Kasus tepi: Jika koleksi masih kosong, tampilkan *empty state* dengan CTA menuju pemindai ISBN atau input manual.

### F-02 & F-03 Pemindai Barcode ISBN & Autofill
- Given pengguna memindai barcode ISBN yang valid dan belum ada di koleksi, when Google Books API mengembalikan metadata dan `cover_url`, then formulir tambah buku terbuka dengan field dan pratinjau sampul terisi otomatis dalam waktu `< 10 detik`.
- Kasus tepi: Jika izin kamera ditolak, tampilkan panduan izin dan tombol **Input Manual**.

### F-04 Pencegahan Duplikat ISBN
- Given buku dengan ISBN `9789792248616` sudah ada di koleksi, when pengguna memindai `978-979-224-861-6`, then sistem memblokir formulir baru, menampilkan peringatan duplikat, dan menyediakan tombol menuju layar detail buku tersebut.

### F-05 & F-06 Input Manual & Generated Book Cover
- Given ISBN tidak ditemukan di Google Books API atau pengguna memilih input manual, when pengguna mengisi judul dan penulis tanpa `cover_url`, then nomor ISBN (bila ada) tetap terbawa dan komponen *Generated Book Cover* dirender secara langsung.

### F-07, F-08, F-09, F-10 Detail, Sunting, Peminjaman & Hapus
- Given pengguna membuka detail buku berstatus *Tersedia*, when pengguna menekan **Catat Dipinjam Teman**, mengisi nama peminjam dan tanggal pinjam pada *popup modal*, lalu menyimpan, then status berubah menjadi *Dipinjam* tanpa mengubah status bacaan; dan saat **Tandai Sudah Dikembalikan** ditekan, `borrower_name` dan `borrowed_at` dikosongkan (`""`).
- Given pengguna menekan **Hapus Buku** dan mengonfirmasi dialog, when permintaan `delete` ke GAS App berhasil, then buku dihapus dari daftar dan spreadsheet.

### F-11, F-12, F-13 Error Handling, Filter & Preferensi Tampilan
- Given request ke GAS App/Google Books melewati batas `15 detik` atau jaringan terputus, when operasi berlangsung, then tampilkan pesan galat dan tombol **Coba Lagi** tanpa *crash*.
- Given pengguna mengganti tema (Terang/Gelap) atau tipografi (*Sans-Serif*/*Serif Buku*) di pengaturan, when perubahan dipilih, then seluruh UI langsung menyesuaikan dan preferensi tersimpan lokal.

## Kebutuhan non-fungsional
- **Platform:** Android minimum **Android 8.0 (API Level 26)**, orientasi terkunci **Portrait**.
- **Timeout Jaringan:** Maksimum `15 detik` untuk seluruh panggilan HTTP (GAS App dan Google Books API).
- **Performa & Animasi:** Transisi `150–260 ms` pada `60 fps` serta menghormati pengaturan sistem *Reduce Motion*.
- **State Latar Belakang:** Formulir yang belum disimpan tidak disimpan otomatis bila aplikasi ditutup/di-*background*.
- **Aksesibilitas:** Kontras warna memenuhi WCAG AA (`>= 4.5:1`) pada mode Terang dan Gelap; area sentuh minimal `44 x 44 dp`; ikon wajib garis monokrom.

## Di luar cakupan (Pasca-MVP)
- Fitur **Wishlist Buku** (daftar incaran baca & pemindahan ke koleksi utama — dijadwalkan ke v1.1).
- Dukungan Web, iOS, dan Desktop.
- Penyimpanan *offline-first* / antrean sinkronisasi lokal.
- Riwayat peminjaman historis per buku dan manajemen multi-eksemplar (*copies*).
- Autentikasi multi-pengguna.

## Batasan dan asumsi
- Rombakan penuh (*clean slate*) dari kode lama `book_apps-dev` menggunakan Flutter untuk Android.
- Sumber kebenaran data berada di Google Sheets (`Books`) via GAS App Web App URL; kontrak endpoint mengikuti `@docs/API_SPEC.md` (implementasi `Code.gs` dikerjakan terpisah).
- `[ASUMSI] A-01`: Pengguna tunggal mengoperasikan satu *deployment* GAS App pribadi.
- `[ASUMSI] A-02`: Rentang sapaan waktu lokal: Pagi (`04.00–10.59`), Siang (`11.00–14.59`), Sore (`15.00–18.29`), Malam (`18.30–03.59`).
- `[ASUMSI] A-03`: Google Books API publik tanpa API key berbayar memadai untuk penggunaan koleksi pribadi.