/// Model untuk menyimpan data jadwal sholat
class PrayerTimes {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String imsak;
  final String hijriDate;
  final String hijriMonth;
  final String hijriYear;

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

  /// Parse dari response EQuran.id API (jadwal harian)
  factory PrayerTimes.fromEquranJson(Map<String, dynamic> day) {
    final hijri = _calculateHijri(DateTime.now());
    return PrayerTimes(
      imsak: day['imsak'] ?? '--:--',
      fajr: day['subuh'] ?? '--:--',
      sunrise: day['terbit'] ?? '--:--',
      dhuhr: day['dzuhur'] ?? '--:--',
      asr: day['ashar'] ?? '--:--',
      maghrib: day['maghrib'] ?? '--:--',
      isha: day['isya'] ?? '--:--',
      hijriDate: hijri['date']!,
      hijriMonth: hijri['month']!,
      hijriYear: hijri['year']!,
    );
  }

  /// Parse dari response Aladhan API (fallback)
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

  /// Hitung tanggal Hijriyah secara lokal (algoritma Umm al-Qura)
  static Map<String, String> _calculateHijri(DateTime date) {
    final hijriMonthNames = [
      'Muharram',
      'Safar',
      'Rabi\'ul Awal',
      'Rabi\'ul Akhir',
      'Jumadil Awal',
      'Jumadil Akhir',
      'Rajab',
      'Sya\'ban',
      'Ramadan',
      'Syawal',
      'Dzulqa\'dah',
      'Dzulhijjah',
    ];

    // Algoritma Julian Day → Hijri
    final jd = _gregorianToJulian(date.year, date.month, date.day);
    final l = jd - 1948440 + 10632;
    final n = ((l - 1) ~/ 10631);
    final ll = l - 10631 * n + 354;
    final j = ((10985 - ll) ~/ 5316) * ((50 * ll) ~/ 17719) +
        (ll ~/ 5670) * ((43 * ll) ~/ 15238);
    final lll = ll -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final month = (24 * lll) ~/ 709;
    final day = lll - (709 * month) ~/ 24;
    final year = 30 * n + j - 30;

    return {
      'date': day.toString(),
      'month': month >= 1 && month <= 12 ? hijriMonthNames[month - 1] : '',
      'year': year.toString(),
    };
  }

  static int _gregorianToJulian(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final a = year ~/ 100;
    final b = 2 - a + a ~/ 4;
    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524;
  }

  static String _cleanTime(String? time) {
    if (time == null) return '--:--';
    return time.replaceAll(RegExp(r'\s*\(.*\)'), '').trim();
  }

  /// Sholat berikutnya
  String get nextPrayerName {
    final now = DateTime.now();
    for (final prayer in _prayerList) {
      final time = _parseTime(prayer['time']!);
      if (time != null && now.isBefore(time)) return prayer['name']!;
    }
    return 'Subuh';
  }

  String get nextPrayerTime {
    final now = DateTime.now();
    for (final prayer in _prayerList) {
      final time = _parseTime(prayer['time']!);
      if (time != null && now.isBefore(time)) return prayer['time']!;
    }
    return fajr;
  }

  List<Map<String, String>> get _prayerList => [
        {'name': 'Subuh', 'time': fajr},
        {'name': 'Dzuhur', 'time': dhuhr},
        {'name': 'Ashar', 'time': asr},
        {'name': 'Maghrib', 'time': maghrib},
        {'name': 'Isya', 'time': isha},
      ];

  List<Map<String, String>> get displayPrayers => _prayerList;

  String get formattedHijriDate => '$hijriDate $hijriMonth $hijriYear H';

  DateTime? _parseTime(String time) {
    try {
      final parts = time.split(':');
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, int.parse(parts[0]),
          int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }
}
