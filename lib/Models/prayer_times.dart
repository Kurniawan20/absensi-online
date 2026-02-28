/// Model untuk menyimpan data jadwal sholat dari Aladhan API
class PrayerTimes {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String imsak;
  final String hijriDate; // Tanggal Hijriyah (readable)
  final String hijriMonth; // Nama bulan Hijriyah
  final String hijriYear; // Tahun Hijriyah

  PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.imsak,
    required this.hijriDate,
    required this.hijriMonth,
    required this.hijriYear,
  });

  /// Parse dari response Aladhan API
  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    final timings = json['timings'] as Map<String, dynamic>;
    final hijri = json['date']['hijri'] as Map<String, dynamic>;

    return PrayerTimes(
      fajr: _cleanTime(timings['Fajr']),
      sunrise: _cleanTime(timings['Sunrise']),
      dhuhr: _cleanTime(timings['Dhuhr']),
      asr: _cleanTime(timings['Asr']),
      maghrib: _cleanTime(timings['Maghrib']),
      isha: _cleanTime(timings['Isha']),
      imsak: _cleanTime(timings['Imsak']),
      hijriDate: hijri['day'] ?? '',
      hijriMonth: hijri['month']?['en'] ?? '',
      hijriYear: hijri['year'] ?? '',
    );
  }

  /// Bersihkan format waktu (hapus timezone offset jika ada, misal "(WIB)")
  static String _cleanTime(String? time) {
    if (time == null) return '--:--';
    return time.replaceAll(RegExp(r'\s*\(.*\)'), '').trim();
  }

  /// Dapatkan nama sholat selanjutnya berdasarkan waktu sekarang
  String get nextPrayerName {
    final now = DateTime.now();
    final prayers = _prayerList;

    for (final prayer in prayers) {
      final time = _parseTime(prayer['time']!);
      if (time != null && now.isBefore(time)) {
        return prayer['name']!;
      }
    }

    // Semua sholat hari ini sudah lewat, sholat selanjutnya adalah Subuh
    return 'Subuh';
  }

  /// Dapatkan waktu sholat selanjutnya
  String get nextPrayerTime {
    final now = DateTime.now();
    final prayers = _prayerList;

    for (final prayer in prayers) {
      final time = _parseTime(prayer['time']!);
      if (time != null && now.isBefore(time)) {
        return prayer['time']!;
      }
    }

    return fajr; // Fallback ke Subuh
  }

  /// Daftar sholat berurutan
  List<Map<String, String>> get _prayerList => [
        {'name': 'Subuh', 'time': fajr},
        {'name': 'Dzuhur', 'time': dhuhr},
        {'name': 'Ashar', 'time': asr},
        {'name': 'Maghrib', 'time': maghrib},
        {'name': 'Isya', 'time': isha},
      ];

  /// Dapatkan semua waktu sholat sebagai list untuk ditampilkan di UI
  List<Map<String, String>> get displayPrayers => [
        {'name': 'Subuh', 'time': fajr},
        {'name': 'Dzuhur', 'time': dhuhr},
        {'name': 'Ashar', 'time': asr},
        {'name': 'Maghrib', 'time': maghrib},
        {'name': 'Isya', 'time': isha},
      ];

  /// Format tanggal Hijriyah untuk tampilan
  String get formattedHijriDate => '$hijriDate $hijriMonth $hijriYear H';

  /// Parse string waktu (HH:mm) ke DateTime hari ini
  DateTime? _parseTime(String time) {
    try {
      final parts = time.split(':');
      final now = DateTime.now();
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (_) {
      return null;
    }
  }
}
