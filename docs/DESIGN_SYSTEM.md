# Design System

- **Pustaka UI & Tema:** Flutter Material 3 (`useMaterial3: true`) dengan kustomisasi penuh token warna, tipografi, radius, dan elevasi.
- **Referensi Visual:** `design/palette-preview.html` dan `design/app-screens-mockup.html`.

## Token

### Warna (Mode Terang & Mode Gelap)
| Peran Token | Terang (Light) | Gelap (Dark) | Penggunaan |
| :--- | :--- | :--- | :--- |
| `primary` | `#3E6251` | `#84B59F` | Kartu CTA utama, tombol aksi primer, indikator aktif |
| `onPrimary` | `#FFFFFF` | `#12211A` | Teks & ikon di atas `primary` |
| `secondary` | `#B34B24` | `#F0855E` | Badge status *Dipinjam*, pill tab aktif di navbar bawah |
| `onSecondary` | `#FFFFFF` | `#261008` | Teks & ikon di atas `secondary` |
| `accent` | `#D99B26` | `#F2C14E` | Sorotan hangat sekunder |
| `background` | `#FAF6F0` | `#161615` | Latar utama halaman (*Warm Paper* / *Warm Charcoal*) |
| `surface` | `#FFFFFF` | `#232220` | Kartu buku, kartu statistik, popup modal, navbar |
| `surfaceAlt` | `#F1EAE0` | `#2E2C29` | Filter chip tidak aktif, kotak pratinjau sampul |
| `text` | `#1E1D1B` | `#F3EFEA` | Judul buku, heading, teks isi utama |
| `textMuted` | `#5E5A54` | `#ACA69E` | Nama penulis, label metadata, caption |
| `border` | `#E2D9CC` | `#383531` | Garis tepi kartu, input field, pemisah tabel |
| `success` | `#2E6F40` | `#6FCF97` | Badge status *Selesai Dibaca*, notifikasi sukses |
| `warning` | `#9A6300` | `#F2C94C` | Banner peringatan duplikat ISBN |
| `error` | `#B8332A` | `#EB6A62` | Pesan galat koneksi/timeout GAS App, tombol hapus |
| `info` | `#2B5F82` | `#6CAEE0` | Badge status *Sedang Dibaca* |

### Tipografi
- **Pilihan Font (dapat diganti pengguna via `SettingsPage`):**
  - `sans` (Default): `Plus Jakarta Sans` (fallback sistem sans-serif).
  - `serif` (*Serif Buku*): `Lora` (fallback sistem serif).
- **Skala Ukuran:** `xs: 11–12sp`, `sm: 13–14sp`, `base: 16sp`, `lg: 18sp`, `xl: 20sp`, `2xl: 24sp`.

### Spasi, Radius, Elevasi & Gerak
- **Spasi (kelipatan 4):** `4, 8, 12, 16, 24, 32, 48 dp`.
- **Radius Sudut:** `sm: 8dp` (input), `md: 14dp` (kartu buku & statistik), `lg: 22dp` (hero card & modal sheet), `full: 999dp` (tombol pill, chip, navbar).
- **Durasi Animasi:** `fast: 150ms`, `base: 250ms` (wajib cek `MediaQuery.of(context).disableAnimations` untuk menghormati *Reduce Motion*).

## Komponen reusable
| Komponen | Varian | Aturan pakai |
| :--- | :--- | :--- |
| `BookCoverView` | `small` (54x78dp), `medium` (68x98dp), `large` (118x168dp) | Tampilkan `CachedNetworkImage` jika `coverUrl` non-kosong & valid; otomatis fallback ke `GeneratedBookCover` jika kosong atau gagal muat (`BR-05`). |
| `GeneratedBookCover` | `sage`, `terracotta`, `slate`, `amber` | Wajib memiliki lipatan punggung buku di sisi kiri (11% lebar, overlay gelap 20%), cincin tipis di kanan atas, judul di kiri atas, dan penulis di kiri bawah. |
| `StatusBadge` | `unread`, `reading`, `finished`, `borrowed` | Gunakan latar transparan 14–18% dari warna semantik dan teks kontras tinggi; pisahkan badge baca dari badge pinjam. |
| `FloatingBottomNav` | 3 item (*Koleksi*, *Scan*, *Setelan*) | Label teks diletakkan **di bawah ikon** dan **hanya dirender pada item yang sedang aktif**. |
| `BorrowModalSheet` | Bottom sheet modal | Hanya memuat input `Nama Peminjam` dan `Tanggal Pinjam`; jangan mencampur field metadata buku di dalamnya. |
| `ErrorRetryView` | Inline / Full-state | Menampilkan ikon monokrom, pesan error spesifik, dan tombol pill **Coba Lagi** (`minHeight: 44dp`). |

## Aturan
- **Dilarang hardcode warna hex atau ukuran font** di dalam widget fitur; selalu rujuk `Theme.of(context).colorScheme` / `AppColors` extension dan `Theme.of(context).textTheme`.
- **Ikon Monokrom:** Seluruh ikon wajib menggunakan gaya garis monokrom (`Icons.*_outlined`) yang mengikuti warna konten (`currentColor`); dilarang memakai emoji atau ikon multi-warna di UI.
- **Target Sentuh & Kontras:** Setiap elemen interaktif wajib memiliki tinggi/lebar minimum `44dp`, dan rasio kontras teks terhadap latar wajib `>= 4.5:1`.