/// Status progres baca buku (`@docs/DATA_MODEL.md`).
/// Independen dari status peminjaman teman (`isBorrowed`).
enum ReadingStatus {
  unread('unread', 'Belum Dibaca'),
  reading('reading', 'Sedang Dibaca'),
  finished('finished', 'Selesai');

  const ReadingStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// Mengonversi string dari JSON/Sheet menjadi [ReadingStatus].
  /// Default ke [ReadingStatus.unread] apabila kosong atau tidak dikenali.
  static ReadingStatus fromApiValue(String? value) {
    final clean = value?.trim().toLowerCase();
    for (final status in ReadingStatus.values) {
      if (status.apiValue == clean) {
        return status;
      }
    }
    return ReadingStatus.unread;
  }
}
