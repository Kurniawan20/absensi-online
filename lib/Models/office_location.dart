import 'dart:convert';

/// Model untuk menyimpan data lokasi kantor
class OfficeLocation {
  final String nama;
  final String alamat;
  final double latitude;
  final double longitude;
  final double radius;

  OfficeLocation({
    required this.nama,
    required this.alamat,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  /// Create dari JSON
  factory OfficeLocation.fromJson(Map<String, dynamic> json) {
    return OfficeLocation(
      nama: json['nama']?.toString() ?? '',
      alamat: json['alamat']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      radius: double.tryParse(json['radius']?.toString() ?? '0') ?? 0.0,
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'alamat': alamat,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    };
  }

  /// Parse list locations dari JSON string
  static List<OfficeLocation> fromJsonString(String jsonString) {
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => OfficeLocation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error parsing locations: $e');
      return [];
    }
  }

  /// Convert list locations ke JSON string
  static String toJsonString(List<OfficeLocation> locations) {
    final jsonList = locations.map((loc) => loc.toJson()).toList();
    return json.encode(jsonList);
  }

  @override
  String toString() {
    return 'OfficeLocation(nama: $nama, alamat: $alamat, lat: $latitude, long: $longitude, radius: $radius)';
  }
}
