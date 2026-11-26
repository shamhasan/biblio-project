# Pertanyaan Terbuka dan Asumsi

## Pertanyaan terbuka
| ID | Pertanyaan | Dampak jika salah | Perlu dijawab sebelum | Status |
| :--- | :--- | :--- | :--- | :--- |
| Q-001 | Pembuatan & deployment skrip Google Apps Script (`Code.gs`) serta Google Sheets dengan tab `Books` (dikerjakan terpisah sebelum pengujian integrasi live). | Aplikasi Flutter tidak dapat melakukan sinkronisasi data nyata ke spreadsheet. | T-010 (Uji Integrasi Live) | Terjawab (`D-010`: URL deployment GAS aktif telah disetel di `ApiConstants.defaultGasWebAppUrl`) |

## Asumsi yang dipakai
| ID | Asumsi | Dipakai di | Alasan |
| :--- | :--- | :--- | :--- |
| A-01 | Pengguna tunggal mengoperasikan satu *deployment* Web App Google Apps Script pribadi yang terhubung ke satu file Google Sheets (`Books`). | `PRD.md`, `API_SPEC.md`, `INTEGRATIONS.md` | Disepakati oleh user; tidak diperlukan sistem login/multi-user. |
| A-02 | Rentang sapaan waktu pada layar *Home* mengikuti jam lokal perangkat: Pagi (`04.00–10.59`), Siang (`11.00–14.59`), Sore (`15.00–18.29`), Malam (`18.30–03.59`). | `PRD.md`, `SCREENS.md`, `TASKS.md` (T-003) | Disepakati oleh user sebagai aturan deterministik untuk unit test. |
| A-03 | Google Books API menggunakan API Key pribadi yang disimpan di `app_secrets.local.dart` (gitignored) dengan fallback otomatis ke OpenLibrary Books API dan form manual jika kuota habis (`D-011`). | `PRD.md`, `TECH_STACK.md`, `INTEGRATIONS.md` | Menghindari limit kuota IP publik (`HTTP 429`) pada Google Books API. |