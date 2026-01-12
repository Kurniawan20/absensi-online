/// Office location configuration
/// Contains all office coordinates and their settings
class OfficeLocationConfig {
  /// Default map position (shown before GPS location is obtained)
  static const double defaultLatitude = 5.543605637891148;
  static const double defaultLongitude = 95.32992029020498;
  static const double defaultZoom = 17.0;

  /// Secondary office locations by office code
  /// Key: office code pattern, Value: OfficeLocation
  static final Map<String, OfficeLocation> secondaryLocations = {
    // Exact match for office code "813"
    '813': OfficeLocation(
      latitude: 5.521261515723264,
      longitude: 95.3300600393016,
      name: 'Kantor 813',
    ),
    // Default for offices starting with "8" (except 813)
    '8_default': OfficeLocation(
      latitude: 5.544926358826539,
      longitude: 95.31200258268379,
      name: 'Kantor Area 8',
    ),
  };

  /// Get secondary location for a given office code
  /// Returns null if no secondary location is configured
  static OfficeLocation? getSecondaryLocation(String? officeCode) {
    if (officeCode == null) return null;

    // Check for exact match first
    if (secondaryLocations.containsKey(officeCode)) {
      return secondaryLocations[officeCode];
    }

    // Check for pattern match (offices starting with "8")
    if (officeCode.startsWith('8')) {
      return secondaryLocations['8_default'];
    }

    return null;
  }

  /// Check if office code has a secondary location
  static bool hasSecondaryLocation(String? officeCode) {
    return getSecondaryLocation(officeCode) != null;
  }
}

/// Represents an office location with coordinates
class OfficeLocation {
  final double latitude;
  final double longitude;
  final String name;

  const OfficeLocation({
    required this.latitude,
    required this.longitude,
    required this.name,
  });
}
