# Model Data

## Diagram relasi
```text
┌──────────────────────────────────────────────┐
│                 Books (Sheet)                │
├──────────────────────────────────────────────┤
│ PK  id              : String (UUID/Timestamp)│
│ UQ* isbn            : String (Nullable)      │
│     title           : String (Required)      │
│     authors         : String                 │
│     publisher       : String                 │
│     published_year  : String (YYYY)          │
│     cover_url       : String (URL)           │
│     reading_status  : Enum (unread|reading|  │
│                       finished)              │
│     is_borrowed     : Boolean (TRUE/FALSE)   │
│     borrower_name   : String (Conditional)   │
│     borrowed_at     : String (YYYY-MM-DD)    │
│     notes           : String                 │
│     created_at      : String (ISO-8601)      │
│     updated_at      : String (ISO-8601)      │
└──────────────────────────────────────────────┘
*UQ kondisional: Unik untuk setiap nilai isbn non-kosong (BR-01).
```

## Entitas

### 1. `Book` (Entitas Utama — Sheet `Books`)
| Field | Tipe | Wajib | Keterangan / aturan validasi |
| :--- | :--- | :--- | :--- |
| `id` | `String` | Ya | Pengenal unik baris buku (dibuat di klien/GAS saat `create`, mis. UUID v4). |
| `isbn` | `String` | Tidak | Nomor ISBN-10 atau ISBN-13 yang sudah dinormalisasi (tanpa `-` atau spasi). Boleh kosong (`""`) untuk buku tanpa ISBN. |
| `title` | `String` | Ya | Judul buku; minimal 1 karakter non-spasi (`title.trim().isNotEmpty`). |
| `authors` | `String` | Tidak | Nama penulis (dipisahkan koma jika lebih dari satu); default `""`. |
| `publisher` | `String` | Tidak | Nama penerbit (terisi otomatis dari Google Books bila tersedia); default `""`. |
| `published_year` | `String` | Tidak | Tahun terbit format `YYYY`; default `""`. |
| `cover_url` | `String` | Tidak | URL gambar sampul dari Google Books API; jika kosong (`""`), UI merender *Generated Book Cover*. |
| `reading_status` | `ReadingStatus` | Ya | Enum string: `unread` (Belum Dibaca), `reading` (Sedang Dibaca), `finished` (Selesai). Default: `unread`. |
| `is_borrowed` | `bool` | Ya | `true` jika sedang dipinjam teman, `false` jika tersedia. Default: `false`. |
| `borrower_name` | `String` | Kondisional | Wajib non-kosong jika `is_borrowed == true`. Wajib dikosongkan (`""`) jika `is_borrowed == false` (BR-03). |
| `borrowed_at` | `String` | Kondisional | Format tanggal `YYYY-MM-DD`; wajib terisi jika `is_borrowed == true`, wajib `""` jika `is_borrowed == false` (BR-03). |
| `notes` | `String` | Tidak | Catatan pribadi pengguna; default `""`. |
| `created_at` | `String` | Ya | Timestamp ISO-8601 UTC/lokal saat buku pertama kali ditambahkan. |
| `updated_at` | `String` | Ya | Timestamp ISO-8601 saat baris terakhir kali diperbarui. |

- **Relasi:** Entitas tunggal datar (*flat table*) pada tab sheet bernama `Books`.
- **Indeks / Unik:** Kolom `id` wajib unik; kolom `isbn` wajib unik di antara seluruh baris yang memiliki `isbn != ""` (divalidasi di klien sebelum `create` maupun di GAS App).
- **Fitur terkait:** `F-01`, `F-03`, `F-04`, `F-05`, `F-06`, `F-07`, `F-08`, `F-09`, `F-10`, `F-12`.

### 2. `AppSettings` (Preferensi Lokal — `SharedPreferences`)
| Key | Tipe | Default | Keterangan |
| :--- | :--- | :--- | :--- |
| `gas_web_app_url` | `String` | `""` | URL deployment Web App Google Apps Script (`https://script.google.com/macros/s/.../exec`). |
| `theme_mode` | `String` | `"light"` | `"light"` atau `"dark"`. |
| `font_family` | `String` | `"sans"` | `"sans"` (*Plus Jakarta Sans*) atau `"serif"` (*Lora*). |

- **Fitur terkait:** `F-13`.

## Aturan data
- **Hard Delete:** Penghapusan buku (`F-10`) menghapus baris secara permanen dari sheet `Books` (tidak memakai *soft delete*).
- **Audit Field:** `created_at` diisi sekali saat pembuatan dan tidak boleh berubah saat `update`; `updated_at` selalu diperbarui setiap kali metadata, status baca, atau status pinjam diubah.
- **Normalisasi ISBN:** Sebelum disimpan atau dibandingkan, hapus seluruh karakter non-alfanumerik (`-`, spasi) dan ubah huruf `x` kecil menjadi `X` kapital (untuk checksum ISBN-10).
- **Data Sensitif:** Tidak ada kata sandi, token rahasia, atau data finansial yang disimpan di spreadsheet.

## Penyimpanan dan sinkronisasi
- **Single Source of Truth:** Google Sheets (`Books`) diakses langsung via HTTPS ke GAS Web App URL.
- **Strategi Sinkronisasi:** *Online-only* dengan *in-memory state* selama aplikasi aktif. Tidak ada database lokal SQLite/Hive dan tidak ada *offline queue* di MVP.