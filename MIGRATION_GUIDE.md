# Migration Guide - Storage Configuration Update

## Problem
App menunjukkan "Sesi anda telah berakhir" setelah login karena perubahan konfigurasi FlutterSecureStorage.

## Root Cause
- Old app menggunakan `const FlutterSecureStorage()` (default config)
- New app menggunakan `StorageConfig.secureStorage` (dengan encryptedSharedPreferences)
- Token disimpan di storage lama, tapi dibaca dari storage baru → Token not found

## Solution

### Step 1: Uninstall Old App (WAJIB!)
```bash
# Android
adb uninstall com.example.monitoring_project

# Atau manual dari device:
Settings → Apps → HABA → Uninstall
```

### Step 2: Clean Build
```bash
flutter clean
flutter pub get
```

### Step 3: Build Fresh App
```bash
# Debug
flutter run

# Release
flutter build apk --release
```

### Step 4: Test Login
1. Login dengan credentials
2. Check console log: "Token found with length: XXX"
3. Navigate ke halaman Kehadiran
4. Should work without "Session Expired" error ✅

## Files Updated

### Core Storage Config
- ✅ `lib/utils/storage_config.dart` (NEW - centralized config)
- ✅ `lib/services/secure_storage_service.dart`
- ✅ `lib/repository/login_repository.dart`
- ✅ `lib/services/attendance_service.dart`

### UI Files
- ✅ `lib/screens/page_login.dart`
- ✅ `lib/screens/page_presence.dart`
- ✅ `lib/screens/home_page.dart`

### Files NOT Updated (Optional)
- ⚠️ `lib/screens/page_profile.dart`
- ⚠️ `lib/screens/page_rekap_absensi.dart`
- ⚠️ `lib/repository/presence_repository.dart`
- ⚠️ `lib/controller/HomeController.dart`

## Verification

### Check Token After Login
```dart
// In page_login.dart after successful login
final storage = StorageConfig.secureStorage;
final token = await storage.read(key: 'auth_token');
print('Token present: ${token != null}');
```

### Check Token in Presence Page
```dart
// In page_presence.dart when checking attendance
final storage = StorageConfig.secureStorage;
var token = await storage.read(key: 'auth_token');
print('Token in presence: ${token != null}');
```

## Important Notes

1. **Uninstall is REQUIRED** - Old storage data must be cleared
2. **All users must reinstall** - This is a breaking change
3. **Data will be lost** - Users need to login again
4. **Biometric settings reset** - Users need to re-enable biometric

## Rollback (If Needed)

If you need to rollback to old storage:

```dart
// In lib/utils/storage_config.dart
class StorageConfig {
  static const FlutterSecureStorage secureStorage = FlutterSecureStorage();
  // Remove AndroidOptions and IOSOptions
}
```

Then rebuild and reinstall.
