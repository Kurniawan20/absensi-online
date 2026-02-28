import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_times.dart';
import '../models/office_location.dart' as model;
import '../constants/office_location_config.dart';

/// Service untuk mengambil jadwal sholat dari Aladhan API
/// Menggunakan method Kemenag RI (method=20)
class PrayerTimeService {
  static const _baseUrl = 'https://api.aladhan.com/v1/timings';
  static const _cacheKey = 'cached_prayer_times';
  static const _cacheDateKey = 'cached_prayer_date';

  static const int _maxRetries = 3;

  /// Ambil jadwal sholat hari ini
  /// Otomatis cache agar tidak hit API berulang di hari yang sama
  /// Retry otomatis hingga [_maxRetries] kali jika gagal koneksi
  Future<PrayerTimes?> getTodayPrayerTimes() async {
    // Cek cache dulu
    final cached = await _getCachedPrayerTimes();
    if (cached != null) return cached;

    // Ambil koordinat dari lokasi kantor
    final coords = await _getCoordinates();

    // Format tanggal: DD-MM-YYYY
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

    // Panggil API dengan retry
    final url = Uri.parse(
        '$_baseUrl/$dateStr?latitude=${coords['lat']}&longitude=${coords['lng']}&method=20');

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        print('Fetching prayer times (percobaan $attempt/$_maxRetries)...');
        final response = await http.get(url).timeout(
              const Duration(seconds: 10),
            );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          if (json['code'] == 200) {
            final prayerTimes = PrayerTimes.fromJson(json['data']);
            await _cachePrayerTimes(response.body, dateStr);
            return prayerTimes;
          }
        }

        // Response bukan 200 atau code bukan 200, lanjut retry
        print('Prayer times: response tidak valid (attempt $attempt)');
      } catch (e) {
        print('Prayer times error (attempt $attempt/$_maxRetries): $e');
      }

      // Tunggu sebelum retry (exponential backoff: 2s, 4s, 8s)
      if (attempt < _maxRetries) {
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }

    // Semua percobaan gagal
    print('Prayer times: semua $_maxRetries percobaan gagal');
    return null;
  }

  /// Ambil koordinat dari SharedPreferences (lokasi kantor pertama)
  /// Fallback ke default coordinates dari OfficeLocationConfig
  Future<Map<String, double>> _getCoordinates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = prefs.getString('office_locations');

      if (locationsJson != null) {
        final locations = model.OfficeLocation.fromJsonString(locationsJson);
        if (locations.isNotEmpty) {
          return {
            'lat': locations.first.latitude,
            'lng': locations.first.longitude,
          };
        }
      }
    } catch (e) {
      print('Error getting coordinates: $e');
    }

    // Fallback ke default
    return {
      'lat': OfficeLocationConfig.defaultLatitude,
      'lng': OfficeLocationConfig.defaultLongitude,
    };
  }

  /// Ambil data cache jika masih hari yang sama
  Future<PrayerTimes?> _getCachedPrayerTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDate = prefs.getString(_cacheDateKey);

      final now = DateTime.now();
      final todayStr =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

      // Cache valid hanya untuk hari yang sama
      if (cachedDate == todayStr) {
        final cachedData = prefs.getString(_cacheKey);
        if (cachedData != null) {
          final json = jsonDecode(cachedData);
          return PrayerTimes.fromJson(json['data']);
        }
      }
    } catch (_) {
      // Cache rusak, abaikan
    }
    return null;
  }

  /// Simpan response API ke cache
  Future<void> _cachePrayerTimes(String responseBody, String dateStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, responseBody);
    await prefs.setString(_cacheDateKey, dateStr);
  }
}
