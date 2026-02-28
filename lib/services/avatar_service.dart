import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarService extends ChangeNotifier {
  static final AvatarService _instance = AvatarService._internal();
  factory AvatarService() => _instance;
  AvatarService._internal();

  static const String _avatarKey = 'selected_avatar';

  // Daftar avatar yang tersedia, dikelompokkan berdasarkan gender
  // Gender: '01' = Pria, '02' = Wanita
  static const List<Map<String, String>> availableAvatars = [
    {
      'id': 'male',
      'path': 'assets/images/avatar_male.png',
      'label': 'Avatar 1',
      'gender': '01',
    },
    {
      'id': 'male_2',
      'path': 'assets/images/avatar_male_2.png',
      'label': 'Avatar 2',
      'gender': '01',
    },
    {
      'id': 'female',
      'path': 'assets/images/avatar_female.png',
      'label': 'Avatar 1',
      'gender': '02',
    },
    {
      'id': 'female_2',
      'path': 'assets/images/avatar_female_2.png',
      'label': 'Avatar 2',
      'gender': '02',
    },
  ];

  /// Mengambil daftar avatar sesuai gender user dari SharedPreferences
  static Future<List<Map<String, String>>> getAvatarsByGender() async {
    final prefs = await SharedPreferences.getInstance();
    final gender = prefs.getString('gender') ?? '01';
    return availableAvatars.where((a) => a['gender'] == gender).toList();
  }

  // Default avatar (Ramadhan: gunakan avatar berpeci)
  static const String defaultAvatar = 'assets/images/avatar_male_2.png';

  // Current selected avatar (cached)
  String _currentAvatar = defaultAvatar;
  String get currentAvatar => _currentAvatar;

  /// Initialize service and load saved avatar
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentAvatar = prefs.getString(_avatarKey) ?? defaultAvatar;
  }

  /// Get the currently selected avatar path
  static Future<String> getSelectedAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarKey) ?? defaultAvatar;
  }

  /// Save the selected avatar path and notify listeners
  Future<void> setSelectedAvatar(String avatarPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarKey, avatarPath);
    _currentAvatar = avatarPath;
    notifyListeners(); // Notify all listeners about the change
  }

  /// Get avatar by ID
  static String getAvatarPathById(String id) {
    final avatar = availableAvatars.firstWhere(
      (a) => a['id'] == id,
      orElse: () => availableAvatars.first,
    );
    return avatar['path'] ?? defaultAvatar;
  }
}
