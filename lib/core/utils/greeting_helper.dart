/// Helper sapaan waktu dinamis sesuai aturan bisnis `BR-04` dan `[ASUMSI] A-02`
/// (`@docs/PRD.md` & `@docs/mockup_interaktif_lengkap_final_mvp.html`):
/// - Pagi (`04:00` – `10:59`, menit `240..659`) -> `'Selamat Pagi'`
/// - Siang (`11:00` – `14:59`, menit `660..899`) -> `'Selamat Siang'`
/// - Sore (`15:00` – `18:29`, menit `900..1109`) -> `'Selamat Sore'`
/// - Malam (`18:30` – `03:59`, menit lainnya) -> `'Selamat Malam'`
abstract final class GreetingHelper {
  /// Mengembalikan teks sapaan Bahasa Indonesia berdasarkan [dateTime] lokal perangkat.
  static String getGreeting([DateTime? dateTime]) {
    final now = dateTime ?? DateTime.now();
    final totalMinutes = now.hour * 60 + now.minute;

    if (totalMinutes >= 240 && totalMinutes <= 659) {
      return 'Selamat Pagi';
    }
    if (totalMinutes >= 660 && totalMinutes <= 899) {
      return 'Selamat Siang';
    }
    if (totalMinutes >= 900 && totalMinutes <= 1109) {
      return 'Selamat Sore';
    }
    return 'Selamat Malam';
  }
}
