# Spesifikasi API

Dokumen ini mendefinisikan kontrak komunikasi antara aplikasi Flutter dan **Google Apps Script Web App (GAS App)** yang terhubung ke Google Sheets (sheet `Books`).

- **Base URL:** Dinamis dari pengaturan pengguna (`gas_web_app_url`, format `https://script.google.com/macros/s/<DEPLOYMENT_ID>/exec`)
- **Format:** `application/json` (UTF-8)
- **Timeout:** `15 detik`
- **Catatan Teknis GAS:** Endpoint `POST` pada Google Apps Script melakukan HTTP `302` redirect ke `script.googleusercontent.com`. Client HTTP (`Dio`) wajib mengizinkan redirect atau menangani respons JSON akhir, dan mengirimkan header `Content-Type: text/plain;charset=utf-8` atau `application/json` sesuai kompatibilitas CORS/GAS.
- **Format Error Standar:**
```json
{
  "status": "error",
  "error": {
    "code": "DUPLICATE_ISBN | NOT_FOUND | VALIDATION_ERROR | INTERNAL_ERROR",
    "message": "Penjelasan galat yang dapat dibaca pengguna"
  }
}
```

---

## Koleksi Buku (`Books`)

### 1. `GET <GAS_WEB_APP_URL>?action=list`
Mengambil seluruh daftar buku dari sheet `Books`.
- **Fitur:** `F-01`, `F-04`, `F-12`
- **Query Parameters:** `action=list` (opsional jika default `doGet` mengembalikan list)
- **Response 200 (Sukses):**
```json
{
  "status": "ok",
  "data": [
    {
      "id": "bk-1732510800000",
      "isbn": "9789792248616",
      "title": "Negeri 5 Menara",
      "authors": "Ahmad Fuadi",
      "publisher": "Gramedia Pustaka Utama",
      "published_year": "2009",
      "cover_url": "",
      "reading_status": "reading",
      "is_borrowed": false,
      "borrower_name": "",
      "borrowed_at": "",
      "notes": "Buku favorit masa kuliah",
      "created_at": "2026-11-25T08:00:00Z",
      "updated_at": "2026-11-25T08:00:00Z"
    }
  ]
}
```
- **Error:** `500 INTERNAL_ERROR` (sheet `Books` tidak ditemukan atau galat eksekusi script).

---

### 2. `POST <GAS_WEB_APP_URL>` (`action: "create"`)
Menambahkan satu baris buku baru ke sheet `Books`.
- **Fitur:** `F-03`, `F-04`, `F-05`
- **Request Body:**
```json
{
  "action": "create",
  "data": {
    "id": "bk-1732514400000",
    "isbn": "9786020633176",
    "title": "Atomic Habits",
    "authors": "James Clear",
    "publisher": "Gramedia",
    "published_year": "2019",
    "cover_url": "https://books.google.com/books/content?id=...",
    "reading_status": "unread",
    "is_borrowed": false,
    "borrower_name": "",
    "borrowed_at": "",
    "notes": "",
    "created_at": "2026-11-25T09:00:00Z",
    "updated_at": "2026-11-25T09:00:00Z"
  }
}
```
- **Aturan Validasi:** `id` dan `title` wajib terisi; jika `isbn` tidak kosong dan sudah ada di sheet `Books`, kembalikan error `DUPLICATE_ISBN`.
- **Response 200 (Sukses):**
```json
{
  "status": "ok",
  "data": {
    "id": "bk-1732514400000",
    "isbn": "9786020633176",
    "title": "Atomic Habits"
  }
}
```
- **Error:** `400 VALIDATION_ERROR` (judul kosong), `409 DUPLICATE_ISBN` (ISBN sudah terdaftar).

---

### 3. `POST <GAS_WEB_APP_URL>` (`action: "update"`)
Memperbarui metadata buku, status baca, atau status peminjaman/pengembalian berdasarkan `id`.
- **Fitur:** `F-08`, `F-09`
- **Request Body (Contoh Peminjaman):**
```json
{
  "action": "update",
  "data": {
    "id": "bk-1732514400000",
    "isbn": "9786020633176",
    "title": "Atomic Habits",
    "authors": "James Clear",
    "publisher": "Gramedia",
    "published_year": "2019",
    "cover_url": "https://books.google.com/books/content?id=...",
    "reading_status": "finished",
    "is_borrowed": true,
    "borrower_name": "Raka Pratama",
    "borrowed_at": "2026-11-25",
    "notes": "Dipinjam saat ngopi",
    "updated_at": "2026-11-25T10:30:00Z"
  }
}
```
- **Aturan Validasi:** Jika `is_borrowed == false`, `borrower_name` dan `borrowed_at` wajib bernilai `""` (BR-03).
- **Response 200 (Sukses):**
```json
{
  "status": "ok",
  "data": {
    "id": "bk-1732514400000",
    "updated_at": "2026-11-25T10:30:00Z"
  }
}
```
- **Error:** `404 NOT_FOUND` (`id` tidak ditemukan), `400 VALIDATION_ERROR`.

---

### 4. `POST <GAS_WEB_APP_URL>` (`action: "delete"`)
Menghapus baris buku dari sheet `Books` berdasarkan `id`.
- **Fitur:** `F-10`
- **Request Body:**
```json
{
  "action": "delete",
  "data": {
    "id": "bk-1732514400000"
  }
}
```
- **Response 200 (Sukses):**
```json
{
  "status": "ok",
  "data": {
    "id": "bk-1732514400000",
    "deleted": true
  }
}
```
- **Error:** `404 NOT_FOUND` (`id` tidak ditemukan).