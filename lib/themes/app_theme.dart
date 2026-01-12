import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App color constants
class AppColors {
  // Primary colors
  static const Color primaryGreen = Color.fromRGBO(1, 101, 65, 1);
  static const Color primaryGreenLight = Color.fromRGBO(1, 101, 65, 0.8);
  static const Color primaryGreenDark = Color.fromRGBO(0, 80, 50, 1);

  // Light theme colors
  static const Color lightBackground = Color(0xFFF3F4F6);
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Colors.white;

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);

  // Accent colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
}

/// Light theme configuration
ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  primaryColor: AppColors.primaryGreen,
  scaffoldBackgroundColor: AppColors.lightBackground,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primaryGreen,
    brightness: Brightness.light,
    primary: AppColors.primaryGreen,
    surface: AppColors.lightSurface,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primaryGreen,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    color: AppColors.lightCard,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    floatingLabelStyle: const TextStyle(color: AppColors.primaryGreen),
    labelStyle: TextStyle(color: Colors.grey[600]),
    contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
    border: InputBorder.none,
    filled: true,
    fillColor: Colors.grey[100],
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryGreen,
    ),
  ),
  dividerTheme: DividerThemeData(
    color: Colors.grey[300],
    thickness: 1,
  ),
  fontFamily: 'Poppins',
);

/// Dark theme configuration
ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: AppColors.primaryGreen,
  scaffoldBackgroundColor: AppColors.darkBackground,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primaryGreen,
    brightness: Brightness.dark,
    primary: AppColors.primaryGreen,
    surface: AppColors.darkSurface,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkSurface,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    color: AppColors.darkCard,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    floatingLabelStyle: const TextStyle(color: AppColors.primaryGreen),
    labelStyle: const TextStyle(color: Colors.grey),
    contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
    border: InputBorder.none,
    filled: true,
    fillColor: AppColors.darkCard,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryGreen,
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: Colors.grey,
    thickness: 1,
  ),
  fontFamily: 'Poppins',
);

/// Theme mode notifier for state management
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
}
