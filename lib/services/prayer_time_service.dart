import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_times.dart';
import '../models/office_location.dart' as model;
import '../constants/office_location_config.dart';

/// Service untuk mengambil jadwal sholat.
/// Prioritas: equran.id (GPS + kabkota) → Aladhan (GPS koordinat)
class PrayerTimeService {
  static const _equranBase = 'https://equran.id/api/v2/shalat';
  static const _aladhanBase = 'https://api.aladhan.com/v1/timings';
  static const _nominatimUrl = 'https://nominatim.openstreetmap.org/reverse';

  static const _cacheKey = 'cached_prayer_times';
  static const _cacheDateKey = 'cached_prayer_date';
  static const _cacheSourceKey = 'cached_prayer_source'; // 'equran' | 'aladhan'

  /// Ambil jadwal sholat hari ini
  Future<PrayerTimes?> getTodayPrayerTimes() async {
    // Cek cache
    final cached = await _getCachedPrayerTimes();
    if (cached != null) return cached;

    // Ambil koordinat GPS atau fallback lokasi kantor
    final coords = await _getCoordinates();
    final lat = coords['lat']!;
    final lng = coords['lng']!;

    // Coba equran.id terlebih dahulu
    final result = await _fetchFromEquran(lat, lng);
    if (result != null) return result;

    // Fallback ke Aladhan (langsung pakai koordinat GPS)
    print('[PrayerTime] Fallback ke Aladhan API...');
    return await _fetchFromAladhan(lat, lng);
  }

  // ─── EQuran.id ────────────────────────────────────────────────────────────

  Future<PrayerTimes?> _fetchFromEquran(double lat, double lng) async {
    try {
      // 1. Reverse geocode → provinsi mentah
      final rawAddress = await _reverseGeocode(lat, lng);
      if (rawAddress == null) return null;

      final rawProvinsi = rawAddress['provinsi'] ?? '';
      final rawKabkota = rawAddress['kabkota'] ?? '';
      print('[PrayerTime] Nominatim: "$rawKabkota, $rawProvinsi"');

      // 2. Normalisasi provinsi
      final provinsi = _normalizeProvinsi(rawProvinsi);

      // 3. Ambil daftar kabkota dari equran.id dan fuzzy match
      final kabkota = await _findBestKabkota(provinsi, rawKabkota);
      if (kabkota == null) {
        print(
            '[PrayerTime] Tidak ada kabkota cocok untuk "$rawKabkota" di "$provinsi"');
        return null;
      }
      print('[PrayerTime] Matched: "$kabkota, $provinsi"');

      // 4. Ambil jadwal bulanan
      final now = DateTime.now();
      final response = await http
          .post(
            Uri.parse(_equranBase),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'provinsi': provinsi,
              'kabkota': kabkota,
              'bulan': now.month,
              'tahun': now.year,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      if (json['code'] != 200) {
        print('[PrayerTime] equran.id error: ${json['message']}');
        return null;
      }

      // 5. Cari jadwal hari ini
      final jadwalList = json['data']['jadwal'] as List;
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final todayJadwal = jadwalList.firstWhere(
        (j) => j['tanggal_lengkap'] == todayStr,
        orElse: () => null,
      );
      if (todayJadwal == null) return null;

      final prayers = PrayerTimes.fromEquranJson(todayJadwal);
      await _cache(jsonEncode(todayJadwal), 'equran');
      print('[PrayerTime] equran.id berhasil: $kabkota, $provinsi');
      return prayers;
    } catch (e) {
      print('[PrayerTime] equran.id error: $e');
      return null;
    }
  }

  /// Ambil daftar kabkota dari equran.id dan cari yang paling cocok
  Future<String?> _findBestKabkota(String provinsi, String rawKabkota) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_equranBase/kabkota'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'provinsi': provinsi}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body);
      if (json['code'] != 200) return null;

      final List<String> list = List<String>.from(json['data']);

      // Normalisasi kabkota dari Nominatim
      final normalized = _normalizeKabkota(rawKabkota);

      // Cari exact match dulu
      for (final item in list) {
        if (item.toLowerCase() == normalized.toLowerCase()) return item;
      }

      // Cari partial match (nama kota ada di item list)
      final kotaName = rawKabkota
          .replaceAll('Kabupaten ', '')
          .replaceAll('Kota ', '')
          .toLowerCase();
      for (final item in list) {
        if (item.toLowerCase().contains(kotaName)) return item;
      }

      // Cari item yang mengandung bagian nama kota
      for (final item in list) {
        if (kotaName.isNotEmpty && kotaName.length > 3) {
          if (item
              .toLowerCase()
              .contains(kotaName.substring(0, kotaName.length ~/ 2))) {
            return item;
          }
        }
      }

      return null;
    } catch (e) {
      print('[PrayerTime] Gagal ambil daftar kabkota: $e');
      return null;
    }
  }

  // ─── Aladhan fallback ─────────────────────────────────────────────────────

  Future<PrayerTimes?> _fetchFromAladhan(double lat, double lng) async {
    try {
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-${now.year}';

      final url = Uri.parse(
        '$_aladhanBase/$dateStr?latitude=$lat&longitude=$lng&method=20',
      );

      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          final response =
              await http.get(url).timeout(const Duration(seconds: 10));
          if (response.statusCode == 200) {
            final json = jsonDecode(response.body);
            if (json['code'] == 200) {
              final prayers = PrayerTimes.fromJson(json['data']);
              await _cache(response.body, 'aladhan');
              print('[PrayerTime] Aladhan berhasil');
              return prayers;
            }
          }
        } catch (e) {
          print('[PrayerTime] Aladhan attempt $attempt: $e');
        }
        if (attempt < 3) await Future.delayed(Duration(seconds: attempt * 2));
      }
    } catch (e) {
      print('[PrayerTime] Aladhan error: $e');
    }
    return null;
  }

  // ─── Reverse geocode ──────────────────────────────────────────────────────

  Future<Map<String, String>?> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        '$_nominatimUrl?lat=$lat&lon=$lng&format=json&accept-language=id',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'HABA-Attendance-App/1.0 (contact@basitd.id)'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      final address = json['address'] as Map<String, dynamic>?;
      if (address == null) return null;

      final state = (address['state'] as String? ?? '').trim();
      final kabkota = (address['county'] as String? ??
              address['city'] as String? ??
              address['municipality'] as String? ??
              address['village'] as String? ??
              '')
          .trim();

      return {'provinsi': state, 'kabkota': kabkota};
    } catch (e) {
      print('[PrayerTime] Nominatim error: $e');
      return null;
    }
  }

  // ─── Normalisasi ──────────────────────────────────────────────────────────

  String _normalizeProvinsi(String raw) {
    const map = {
      'Daerah Khusus Ibukota Jakarta': 'DKI Jakarta',
      'Daerah Istimewa Yogyakarta': 'DI Yogyakarta',
      'Kepulauan Bangka Belitung': 'Bangka Belitung',
    };
    return map[raw] ?? raw;
  }

  String _normalizeKabkota(String raw) {
    if (raw.startsWith('Kota ') || raw.startsWith('Kab. ')) return raw;
    if (raw.startsWith('Kabupaten ')) {
      return 'Kab. ${raw.substring('Kabupaten '.length)}';
    }
    return raw;
  }

  // ─── GPS ──────────────────────────────────────────────────────────────────

  Future<Map<String, double>> _getCoordinates() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.whileInUse ||
            perm == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 5),
            ),
          );
          print('[PrayerTime] GPS: ${pos.latitude}, ${pos.longitude}');
          return {'lat': pos.latitude, 'lng': pos.longitude};
        }
      }
    } catch (e) {
      print('[PrayerTime] GPS error: $e');
    }

    // Fallback ke lokasi kantor
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = prefs.getString('office_locations');
      if (locationsJson != null) {
        final locs = model.OfficeLocation.fromJsonString(locationsJson);
        if (locs.isNotEmpty) {
          return {'lat': locs.first.latitude, 'lng': locs.first.longitude};
        }
      }
    } catch (e) {
      print('[PrayerTime] Office location error: $e');
    }

    return {
      'lat': OfficeLocationConfig.defaultLatitude,
      'lng': OfficeLocationConfig.defaultLongitude,
    };
  }

  // ─── Cache ────────────────────────────────────────────────────────────────

  Future<PrayerTimes?> _getCachedPrayerTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDate = prefs.getString(_cacheDateKey);
      final now = DateTime.now();
      final todayStr =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

      if (cachedDate != todayStr) return null;

      final cachedData = prefs.getString(_cacheKey);
      final source = prefs.getString(_cacheSourceKey);
      if (cachedData == null) return null;

      final json = jsonDecode(cachedData);
      return source == 'aladhan'
          ? PrayerTimes.fromJson(json)
          : PrayerTimes.fromEquranJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cache(String body, String source) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    await prefs.setString(_cacheKey, body);
    await prefs.setString(_cacheDateKey, todayStr);
    await prefs.setString(_cacheSourceKey, source);
  }
}
