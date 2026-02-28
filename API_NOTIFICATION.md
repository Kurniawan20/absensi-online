# API Notification & Firebase Push Documentation

## Base URL
```
http://your-domain/api
```

## Overview

Sistem notifikasi terdiri dari:
1. **In-App Notifications** - Notifikasi yang disimpan di database dan ditampilkan di aplikasi
2. **Push Notifications** - Notifikasi yang dikirim via Firebase Cloud Messaging (FCM)

---

## Table of Contents

1. [FCM Token Registration](#1-fcm-token-registration)
2. [FCM Token Unregistration](#2-fcm-token-unregistration)
3. [Get Notifications](#3-get-notifications)
4. [Get Unread Count](#4-get-unread-count)
5. [Mark as Read](#5-mark-as-read)
6. [Mark All as Read](#6-mark-all-as-read)
7. [Delete Notification](#7-delete-notification)
8. [Send Test Notification](#8-send-test-notification-admin)
9. [Broadcast Notification](#9-broadcast-notification-admin)
10. [Flutter Integration](#10-flutter-integration)

---

## 1. FCM Token Registration

Mendaftarkan FCM token untuk menerima push notification. Panggil endpoint ini setelah login berhasil.

### Endpoint
```
POST /api/fcm/register
```

### Request Body
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| npp | string | Yes | Nomor Pokok Pegawai |
| fcm_token | string | Yes | FCM token dari Firebase |
| device_type | string | No | Platform: `android` atau `ios` |
| device_id | string | No | Device ID untuk identifikasi device |

### Example Request

```bash
curl -X POST "http://localhost/api/fcm/register" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "npp": "10001",
    "fcm_token": "eK7sH2jK...",
    "device_type": "android",
    "device_id": "abc123xyz..."
  }'
```

### Success Response (200 OK)

```json
{
  "rcode": "00",
  "message": "FCM token registered successfully",
  "data": {
    "id": 15,
    "npp": "10001",
    "fcm_token": "eK7sH2jK...",
    "device_type": "android",
    "device_id": "abc123xyz...",
    "is_active": true,
    "created_at": "2026-02-04T08:00:00.000000Z",
    "updated_at": "2026-02-04T08:00:00.000000Z"
  }
}
```

---

## 2. FCM Token Unregistration

Menonaktifkan FCM token saat logout.

### Endpoint
```
POST /api/fcm/unregister
```

### Request Body
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| fcm_token | string | Yes | FCM token yang akan di-unregister |

### Example Request

```bash
curl -X POST "http://localhost/api/fcm/unregister" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "fcm_token": "eK7sH2jK..."
  }'
```

### Success Response (200 OK)

```json
{
  "rcode": "00",
  "message": "FCM token unregistered"
}
```

---

## 3. Get Notifications

Mendapatkan daftar notifikasi user dengan pagination.

### Endpoint
```
GET /api/notifications
```

### Query Parameters
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| npp | string | Required | Nomor Pokok Pegawai |
| per_page | integer | 20 | Records per page |
| page | integer | 1 | Page number |
| is_read | string | - | Filter: `true` atau `false` |
| type | string | - | Filter by notification type |

### Notification Types
| Type | Description |
|------|-------------|
| attendance_reminder | Pengingat absensi |
| attendance_success | Absensi berhasil |
| device_reset_approved | Request reset device disetujui |
| device_reset_rejected | Request reset device ditolak |
| announcement | Pengumuman |
| news | Berita/artikel baru |
| general | Notifikasi umum |

### Example Request

```bash
# Get all notifications
curl -X GET "http://localhost/api/notifications?npp=10001" \
  -H "Authorization: Bearer <token>"

# Get unread only
curl -X GET "http://localhost/api/notifications?npp=10001&is_read=false" \
  -H "Authorization: Bearer <token>"

# Filter by type
curl -X GET "http://localhost/api/notifications?npp=10001&type=attendance_success" \
  -H "Authorization: Bearer <token>"
```

### Success Response (200 OK)

```json
{
  "rcode": "00",
  "message": "Success",
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 101,
        "npp": "10001",
        "type": "attendance_success",
        "title": "Absensi Berhasil",
        "body": "Absensi masuk berhasil dicatat pada 08:05",
        "data": {
          "attendance_id": 1050,
          "check_type": "check_in"
        },
        "is_read": false,
        "read_at": null,
        "is_push_sent": true,
        "push_sent_at": "2026-02-04T08:05:30.000000Z",
        "created_at": "2026-02-04T08:05:30.000000Z",
        "updated_at": "2026-02-04T08:05:30.000000Z"
      }
    ],
    "first_page_url": "http://localhost/api/notifications?page=1",
    "from": 1,
    "last_page": 5,
    "last_page_url": "http://localhost/api/notifications?page=5",
    "next_page_url": "http://localhost/api/notifications?page=2",
    "path": "http://localhost/api/notifications",
    "per_page": 20,
    "prev_page_url": null,
    "to": 20,
    "total": 95
  }
}
```

---

## 4. Get Unread Count

Mendapatkan jumlah notifikasi yang belum dibaca.

### Endpoint
```
GET /api/notifications/unread-count
```

### Query Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| npp | string | Yes | Nomor Pokok Pegawai |

### Example Request

```bash
curl -X GET "http://localhost/api/notifications/unread-count?npp=10001" \
  -H "Authorization: Bearer <token>"
```

### Success Response (200 OK)

```json
{
  "rcode": "00",
  "message": "Success",
  "unread_count": 5
}
```

---

## 5. Mark as Read

Menandai notifikasi sebagai sudah dibaca.

### Endpoint
```
POST /api/notifications/{id}/read
```

### Path Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | integer | Yes | Notification ID |

### Example Request

```bash
curl -X POST "http://localhost/api/notifications/101/read" \
  -H "Authorization: Bearer <token>"
```

### Success Response (200 OK)

```json
{
  "rcode": "00",
  "message": "Notification marked as read"
}
```

---

## 6. Mark All as Read

Menandai semua notifikasi user sebagai sudah dibaca.

### Endpoint
```
POST /api/notifications/read-all
```

### Request Body
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| npp | string | Yes | Nomor Pokok Pegawai |

### Example Request

```bash
curl -X POST "http://localhost/api/notifications/read-all" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "npp": "10001"
  }'
```

### Success Response (200 OK)

```json
{
  "rcode": "00",
  "message": "All notifications marked as read",
  "updated_count": 5
}
```

---

## 7. Delete Notification

Menghapus notifikasi.

### Endpoint
```
DELETE /api/notifications/{id}
```

### Path Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | integer | Yes | Notification ID |

### Example Request

```bash
curl -X DELETE "http://localhost/api/notifications/101" \
  -H "Authorization: Bearer <token>"
```

### Success Response (200 OK)

```json
{
  "rcode": "00",
  "message": "Notification deleted"
}
```

---

## 8. Send Test Notification (Admin)

Mengirim test notification ke user tertentu.

### Endpoint
```
POST /api/notifications/send-test
```

### Request Body
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| npp | string | Yes | Target user NPP |
| title | string | Yes | Notification title |
| body | string | Yes | Notification body |

### Example Request

```bash
curl -X POST "http://localhost/api/notifications/send-test" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "npp": "10001",
    "title": "Test Notification",
    "body": "This is a test notification"
  }'
```

### Success Response (200 OK)

```json
{
  "rcode": "00",
  "message": "Test notification sent",
  "data": {
    "id": 102,
    "npp": "10001",
    "type": "general",
    "title": "Test Notification",
    "body": "This is a test notification",
    "data": {
      "test": true
    },
    "is_read": false,
    "is_push_sent": true,
    "push_sent_at": "2026-02-04T10:00:00.000000Z",
    "created_at": "2026-02-04T10:00:00.000000Z"
  }
}
```

---

## 9. Broadcast Notification (Admin)

Mengirim broadcast notification ke semua user via topic.

### Endpoint
```
POST /api/notifications/broadcast
```

### Request Body
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| title | string | Yes | Notification title |
| body | string | Yes | Notification body |
| type | string | No | Notification type (default: announcement) |
| data | object | No | Additional data |

### Example Request

```bash
curl -X POST "http://localhost/api/notifications/broadcast" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Pengumuman Penting",
    "body": "Besok tanggal 5 Februari adalah hari libur nasional",
    "type": "announcement",
    "data": {
      "holiday_date": "2026-02-05"
    }
  }'
```

### Success Response (200 OK)

```json
{
  "rcode": "00",
  "message": "Broadcast notification sent",
  "result": {
    "success": true,
    "response": {
      "name": "projects/haba-1f47f/messages/0:1234567890..."
    }
  }
}
```

---

## 10. Flutter Integration

### Setup Firebase di Flutter

1. **Add dependencies** di `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
```

2. **Initialize Firebase** di `main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Request permission
  await FirebaseMessaging.instance.requestPermission();
  
  runApp(MyApp());
}
```

3. **Handle Notifications**:

```dart
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final String baseUrl;
  final String Function() getToken;
  final String Function() getNpp;

  NotificationService({
    required this.baseUrl,
    required this.getToken,
    required this.getNpp,
  });

  /// Initialize FCM and register token
  Future<void> initialize() async {
    // Get FCM token
    String? fcmToken = await _messaging.getToken();
    if (fcmToken != null) {
      await registerToken(fcmToken);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(registerToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification tap (when app was terminated)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });

    // Handle notification tap (when app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Subscribe to 'all' topic for broadcasts
    await _messaging.subscribeToTopic('all');
  }

  /// Register FCM token to backend
  Future<void> registerToken(String fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fcm/register'),
        headers: {
          'Authorization': 'Bearer ${getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'npp': getNpp(),
          'fcm_token': fcmToken,
          'device_type': Platform.isAndroid ? 'android' : 'ios',
          'device_id': await _getDeviceId(),
        }),
      );
      print('FCM token registered: ${response.statusCode}');
    } catch (e) {
      print('Failed to register FCM token: $e');
    }
  }

  /// Unregister token on logout
  Future<void> unregisterToken() async {
    try {
      String? fcmToken = await _messaging.getToken();
      if (fcmToken != null) {
        await http.post(
          Uri.parse('$baseUrl/fcm/unregister'),
          headers: {
            'Authorization': 'Bearer ${getToken()}',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'fcm_token': fcmToken,
          }),
        );
      }
    } catch (e) {
      print('Failed to unregister FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');
    
    // Show local notification or update UI
    _showLocalNotification(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      data: message.data,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'];
    final notificationId = message.data['notification_id'];

    // Navigate based on notification type
    switch (type) {
      case 'attendance_success':
        // Navigate to attendance history
        break;
      case 'device_reset_approved':
        // Navigate to login
        break;
      case 'news':
        // Navigate to news detail
        break;
      default:
        // Navigate to notifications list
        break;
    }
  }

  void _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    // Use flutter_local_notifications package
  }

  Future<String> _getDeviceId() async {
    // Use device_info_plus package
    return 'device_id';
  }
}

// Background message handler (must be top-level function)
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}
```

4. **Usage in App**:

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService(
      baseUrl: 'http://your-api.com/api',
      getToken: () => AuthService.instance.token ?? '',
      getNpp: () => AuthService.instance.user?.npp ?? '',
    );
  }

  void _onLoginSuccess() {
    _notificationService.initialize();
  }

  void _onLogout() {
    _notificationService.unregisterToken();
  }
}
```

5. **Notification List Widget**:

```dart
class NotificationListScreen extends StatefulWidget {
  @override
  _NotificationListScreenState createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  List<Map<String, dynamic>> notifications = [];
  int unreadCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => isLoading = true);
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications?npp=$npp'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      final data = json.decode(response.body);
      setState(() {
        notifications = List<Map<String, dynamic>>.from(data['data']['data']);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _markAsRead(int id) async {
    await http.post(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    await http.post(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'npp': npp}),
    );
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text('Mark All Read'),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return ListTile(
                  leading: Icon(
                    notif['is_read'] ? Icons.notifications : Icons.notifications_active,
                    color: notif['is_read'] ? Colors.grey : Colors.blue,
                  ),
                  title: Text(notif['title']),
                  subtitle: Text(notif['body']),
                  trailing: Text(_formatDate(notif['created_at'])),
                  onTap: () => _markAsRead(notif['id']),
                );
              },
            ),
    );
  }
}
```

---

## Backend Usage (PHP/Laravel)

### Send Notification from Controller

```php
use App\Services\FirebaseService;
use App\Models\Notification;

class AbsensiController extends Controller
{
    protected $firebaseService;

    public function __construct(FirebaseService $firebaseService)
    {
        $this->firebaseService = $firebaseService;
    }

    public function absenMasuk(Request $request)
    {
        // ... save attendance ...

        // Send push notification
        $this->firebaseService->createAndSend(
            $request->npp,
            Notification::TYPE_ATTENDANCE_SUCCESS,
            'Absensi Berhasil',
            'Absensi masuk berhasil dicatat pada ' . now()->format('H:i'),
            [
                'attendance_id' => $attendance->id,
                'check_type' => 'check_in',
            ]
        );

        return response()->json(['rcode' => '00', 'message' => 'Success']);
    }
}
```

### Send Notification for Device Reset Approval

```php
// In DeviceResetController::approve()

$this->firebaseService->createAndSend(
    $resetRequest->npp,
    Notification::TYPE_DEVICE_RESET_APPROVED,
    'Reset Device Disetujui',
    'Permintaan reset device Anda telah disetujui. Silakan login dengan device baru.',
    [
        'request_id' => $resetRequest->id,
    ]
);
```

---

## Response Codes

| rcode | Description |
|-------|-------------|
| 00 | Success |
| 01 | Validation error |
| 81 | Not found |
| 99 | Server error |

---

## Firebase Setup (Backend)

### 1. Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create new)
3. Go to **Project Settings** > **Service Accounts**
4. Click **Generate new private key**
5. Download the JSON file

### 2. Place Credentials

Save the downloaded JSON file to:
```
storage/app/haba-1f47f-firebase-adminsdk-fbsvc-cb25192e11.json
```

### 3. Configure `config/services.php`

```php
'firebase' => [
    'project_id' => env('FIREBASE_PROJECT_ID', 'haba-1f47f'),
    'credentials_path' => env('FIREBASE_CREDENTIALS_PATH', 'haba-1f47f-firebase-adminsdk-fbsvc-cb25192e11.json'),
],
```

### 4. Environment Variables (Optional)

```env
FIREBASE_PROJECT_ID=haba-1f47f
FIREBASE_CREDENTIALS_PATH=haba-1f47f-firebase-adminsdk-fbsvc-cb25192e11.json
```

---

## Changelog

### v1.0.0 (2026-02-04)
- Initial Firebase notification implementation
- FCM V1 API support (OAuth 2.0)
- In-app notification storage
- FCM token management
- Broadcast via topics
- Admin test & broadcast endpoints
