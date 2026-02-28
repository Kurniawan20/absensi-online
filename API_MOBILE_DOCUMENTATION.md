# API Absensi Mobile - Dokumentasi Endpoint

**Version:** 2.0  
**Base URL:** `https://your-domain.com/api`  
**Last Updated:** 30 Januari 2026

---

## Daftar Isi

1. [Informasi Umum](#informasi-umum)
2. [App Version](#app-version)
3. [Authentication](#authentication)
4. [Absensi (Attendance)](#absensi-attendance)
5. [Jam Kerja (Attendance Time)](#jam-kerja-attendance-time)
6. [Device Reset](#device-reset)
7. [Blog/Berita](#blogberita)
8. [Notifikasi](#notifikasi)
9. [Response Codes](#response-codes)
10. [Error Handling](#error-handling)

---

## Informasi Umum

### Headers

Semua request yang memerlukan autentikasi harus menyertakan header berikut:

```
Authorization: Bearer {access_token}
Content-Type: application/json
Accept: application/json
```

### Rate Limiting

- **Login endpoint:** 5 requests per menit
- **Other endpoints:** 60 requests per menit

---

## App Version

### 1. Check App Version

Mengecek versi aplikasi saat startup. **Harus dipanggil sebelum login.**

**Endpoint:** `POST /api/app-version/check`  
**Auth Required:** No

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| platform | string | Yes | Platform: "android" atau "ios" |
| build_number | integer | Yes | Build number aplikasi saat ini |
| version_code | string | No | Version code (e.g., "2.0.1") |

#### Request Example

```json
{
    "platform": "android",
    "build_number": 15,
    "version_code": "2.0.0"
}
```

#### Response Success (200) - No Update Needed

```json
{
    "rcode": "00",
    "message": "Version check completed",
    "data": {
        "needs_update": false,
        "force_update": false,
        "maintenance_mode": false,
        "update_message": null,
        "store_url": null,
        "changelog": null
    }
}
```

#### Response Success (200) - Update Available

```json
{
    "rcode": "00",
    "message": "Update available",
    "data": {
        "needs_update": true,
        "force_update": false,
        "maintenance_mode": false,
        "update_message": "Versi baru tersedia dengan fitur-fitur terbaru!",
        "store_url": "https://play.google.com/store/apps/details?id=com.app.absensi",
        "changelog": "- Fitur absensi baru\n- Perbaikan bug\n- Peningkatan performa"
    }
}
```

#### Response Success (200) - Force Update Required

```json
{
    "rcode": "00",
    "message": "Update required",
    "data": {
        "needs_update": true,
        "force_update": true,
        "maintenance_mode": false,
        "update_message": "Update wajib! Versi lama tidak lagi didukung.",
        "store_url": "https://play.google.com/store/apps/details?id=com.app.absensi",
        "changelog": "- Security patches\n- Critical bug fixes"
    }
}
```

#### Response Success (200) - Maintenance Mode

```json
{
    "rcode": "00",
    "message": "App under maintenance",
    "data": {
        "needs_update": false,
        "force_update": false,
        "maintenance_mode": true,
        "maintenance_message": "Aplikasi sedang dalam pemeliharaan. Silakan coba lagi dalam 2 jam."
    }
}
```

#### Mobile App Logic

```
1. App startup
2. Call POST /api/app-version/check
3. Check response:
   - If maintenance_mode == true:
     → Show maintenance screen, block all features
   - If force_update == true:
     → Show force update dialog, redirect to store
     → User MUST update to continue
   - If needs_update == true (but force_update == false):
     → Show optional update dialog
     → User can skip and continue
   - If all false:
     → Continue to login screen
```

---

### 2. Get Latest Version Info

Mengambil info versi terbaru untuk platform tertentu.

**Endpoint:** `GET /api/app-version/latest/{platform}`  
**Auth Required:** No

#### Path Parameters

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| platform | string | Yes | Platform: "android" atau "ios" |

#### Request Example

```
GET /api/app-version/latest/android
```

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "Success",
    "data": {
        "platform": "android",
        "version_code": "2.1.0",
        "build_number": 20,
        "min_version_code": "2.0.0",
        "min_build_number": 15,
        "store_url": "https://play.google.com/store/apps/details?id=com.app.absensi",
        "changelog": "- New features\n- Bug fixes",
        "maintenance_mode": false
    }
}
```

---

## Authentication

### 1. Login

Autentikasi user dan mendapatkan JWT token.

**Endpoint:** `POST /api/login`  
**Auth Required:** No

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| npp | string | Yes | Nomor Pokok Pegawai |
| password | string | Yes | Password user |
| device_id | string | Yes | Unique device identifier |

#### Request Example

```json
{
    "npp": "10001",
    "password": "password123",
    "device_id": "abc123-device-xyz-456"
}
```

#### Response Success (200)

```json
{
    "rcode": "00",
    "nama": "John Doe",
    "kode_kantor": "0001",
    "nama_kantor": "Kantor Pusat",
    "group": "User",
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "token_type": "Bearer",
    "message": "authenticated"
}
```

#### Response Errors

| rcode | Message | Description |
|-------|---------|-------------|
| 81 | User Tidak Terdaftar | NPP tidak ditemukan di sistem |
| 81 | Device Telah Terdaftar ke User Lain | Device sudah digunakan user lain |
| 81 | Device Tidak Sesuai | Device tidak sama dengan yang terdaftar |
| - | NRK atau Password Salah | Kredensial tidak valid |

---

## Absensi (Attendance)

### 2. Check-In (Absen Masuk)

Mencatat waktu masuk karyawan.

**Endpoint:** `POST /api/absenmasuk`  
**Auth Required:** Yes (Bearer Token)

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| latitude | string | Yes | Latitude lokasi (max 50 chars) |
| longitude | string | Yes | Longitude lokasi (max 50 chars) |
| branch_id | string | No | Kode cabang/kantor |
| npp | string | No | NPP (opsional, diambil dari token) |

#### Request Example

```json
{
    "latitude": "-6.2088",
    "longitude": "106.8456",
    "branch_id": "0001"
}
```

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "Check-in successful"
}
```

#### Response Errors

| rcode | Message | Description |
|-------|---------|-------------|
| 01 | Validation failed | Data tidak valid |
| 82 | You have already checked in today | Sudah absen masuk hari ini |
| 83 | Check-in not available yet | Belum waktunya absen masuk |
| 99 | Server error | Error internal server |

---

### 3. Check-Out (Absen Pulang)

Mencatat waktu pulang karyawan.

**Endpoint:** `POST /api/absenpulang`  
**Auth Required:** Yes (Bearer Token)

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| latitude | string | Yes | Latitude lokasi (max 50 chars) |
| longitude | string | Yes | Longitude lokasi (max 50 chars) |
| branch_id | string | No | Kode cabang/kantor |
| npp | string | No | NPP (opsional, diambil dari token) |

#### Request Example

```json
{
    "latitude": "-6.2088",
    "longitude": "106.8456",
    "branch_id": "0001"
}
```

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "Check-out successful"
}
```

---

### 4. Get Riwayat Absensi

Mengambil riwayat absensi bulanan.

**Endpoint:** `POST /api/getabsen`  
**Auth Required:** Yes (Bearer Token)

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| year | string | Yes | Tahun (4 digit, 2000-2100) |
| month | string | Yes | Bulan (1-12) |
| npp | string | No | NPP (opsional, diambil dari token) |

#### Request Example

```json
{
    "year": "2026",
    "month": "1"
}
```

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "Success",
    "data": [
        {
            "tanggal": "2026-01-30",
            "jam_masuk": "08:00",
            "jam_keluar": "17:00",
            "ket_absensi": "-"
        },
        {
            "tanggal": "2026-01-29",
            "jam_masuk": "08:15",
            "jam_keluar": "17:30",
            "ket_absensi": "-"
        }
    ]
}
```

---

### 5. Get Info Kantor

Mengambil informasi lokasi kantor untuk validasi GPS.

**Endpoint:** `POST /api/kantor`  
**Auth Required:** Yes (Bearer Token)

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| kode_kantor | string | Yes | Kode kantor/cabang |

> **Note:** NPP diambil dari JWT token, tidak perlu dikirim di request body.

#### Request Example

```json
{
    "kode_kantor": "010"
}
```

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "Success",
    "data": {
        "kode_kantor": "010",
        "nama_kantor": "Kantor Pusat Jakarta",
        "latitude": "-6.2088",
        "longitude": "106.8456",
        "radius": 100
    }
}
```

---

## Jam Kerja (Attendance Time)

Pengaturan jam kerja untuk validasi waktu absensi.

### 1. Get Jam Kerja Aktif

Mengambil pengaturan jam kerja yang sedang aktif. **Endpoint ini paling relevan untuk mobile app.**

**Endpoint:** `GET /api/jam-absensi/active`  
**Auth Required:** Yes (Bearer Token)

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "Success",
    "data": {
        "id": 1,
        "nama": "Jam Kerja Normal",
        "start_jam_masuk": "07:00:00",
        "end_jam_masuk": "09:00:00",
        "start_jam_pulang": "16:00:00",
        "end_jam_pulang": "18:00:00",
        "is_active": true,
        "created_at": "2026-01-01T00:00:00.000000Z",
        "updated_at": "2026-01-01T00:00:00.000000Z"
    }
}
```

#### Response Not Found (404)

```json
{
    "rcode": "81",
    "message": "No active attendance time setting found"
}
```

#### Field Description

| Field | Type | Description |
|-------|------|-------------|
| nama | string | Nama pengaturan jam kerja |
| start_jam_masuk | time | Waktu mulai bisa absen masuk |
| end_jam_masuk | time | Waktu terakhir bisa absen masuk |
| start_jam_pulang | time | Waktu mulai bisa absen pulang |
| end_jam_pulang | time | Waktu terakhir bisa absen pulang |
| is_active | boolean | Apakah pengaturan ini yang aktif |

---

### 2. Get Semua Jam Kerja

Mengambil semua pengaturan jam kerja (untuk admin dashboard).

**Endpoint:** `GET /api/jam-absensi`  
**Auth Required:** Yes (Bearer Token)

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "Success",
    "data": [
        {
            "id": 1,
            "nama": "Jam Kerja Normal",
            "start_jam_masuk": "07:00:00",
            "end_jam_masuk": "09:00:00",
            "start_jam_pulang": "16:00:00",
            "end_jam_pulang": "18:00:00",
            "is_active": true
        },
        {
            "id": 2,
            "nama": "Jam Kerja Ramadhan",
            "start_jam_masuk": "07:30:00",
            "end_jam_masuk": "09:00:00",
            "start_jam_pulang": "15:00:00",
            "end_jam_pulang": "17:00:00",
            "is_active": false
        }
    ]
}
```

---

### 3. Get Detail Jam Kerja

Mengambil detail pengaturan jam kerja berdasarkan ID.

**Endpoint:** `GET /api/jam-absensi/{id}`  
**Auth Required:** Yes (Bearer Token)

#### Path Parameters

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | Yes | ID jam kerja |

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "Success",
    "data": {
        "id": 1,
        "nama": "Jam Kerja Normal",
        "start_jam_masuk": "07:00:00",
        "end_jam_masuk": "09:00:00",
        "start_jam_pulang": "16:00:00",
        "end_jam_pulang": "18:00:00",
        "is_active": true
    }
}
```

---

### 4. Create Jam Kerja (Admin)

Membuat pengaturan jam kerja baru.

**Endpoint:** `POST /api/jam-absensi`  
**Auth Required:** Yes (Bearer Token)

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| nama | string | Yes | Nama pengaturan (max 100 chars) |
| start_jam_masuk | time | Yes | Format: HH:mm:ss |
| end_jam_masuk | time | No | Format: HH:mm:ss |
| start_jam_pulang | time | Yes | Format: HH:mm:ss |
| end_jam_pulang | time | No | Format: HH:mm:ss |
| is_active | boolean | No | Set sebagai aktif (default: false) |

#### Request Example

```json
{
    "nama": "Jam Kerja Shift Malam",
    "start_jam_masuk": "20:00:00",
    "end_jam_masuk": "22:00:00",
    "start_jam_pulang": "04:00:00",
    "end_jam_pulang": "06:00:00",
    "is_active": false
}
```

#### Response Success (201)

```json
{
    "rcode": "00",
    "message": "Attendance time setting created successfully",
    "data": {
        "id": 3,
        "nama": "Jam Kerja Shift Malam",
        "start_jam_masuk": "20:00:00",
        "end_jam_masuk": "22:00:00",
        "start_jam_pulang": "04:00:00",
        "end_jam_pulang": "06:00:00",
        "is_active": false
    }
}
```

---

### 5. Update Jam Kerja (Admin)

Mengupdate pengaturan jam kerja.

**Endpoint:** `PUT /api/jam-absensi/{id}`  
**Auth Required:** Yes (Bearer Token)

#### Request Body

Semua field opsional, hanya kirim field yang ingin diupdate.

```json
{
    "start_jam_masuk": "07:30:00",
    "is_active": true
}
```

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "Attendance time setting updated successfully",
    "data": {
        "id": 1,
        "nama": "Jam Kerja Normal",
        "start_jam_masuk": "07:30:00",
        "end_jam_masuk": "09:00:00",
        "start_jam_pulang": "16:00:00",
        "end_jam_pulang": "18:00:00",
        "is_active": true
    }
}
```

---

### 6. Delete Jam Kerja (Admin)

Menghapus pengaturan jam kerja.

**Endpoint:** `DELETE /api/jam-absensi/{id}`  
**Auth Required:** Yes (Bearer Token)

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "Attendance time setting deleted successfully",
    "deleted_nama": "Jam Kerja Shift Malam"
}
```

#### Response Error (400)

```json
{
    "rcode": "82",
    "message": "Cannot delete the last attendance time setting"
}
```

---

### 7. Set Jam Kerja Aktif (Admin)

Mengaktifkan pengaturan jam kerja tertentu. Pengaturan lain akan otomatis dinonaktifkan.

**Endpoint:** `POST /api/jam-absensi/{id}/set-active`  
**Auth Required:** Yes (Bearer Token)

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "Attendance time setting activated successfully",
    "data": {
        "id": 2,
        "nama": "Jam Kerja Ramadhan",
        "start_jam_masuk": "07:30:00",
        "end_jam_masuk": "09:00:00",
        "start_jam_pulang": "15:00:00",
        "end_jam_pulang": "17:00:00",
        "is_active": true
    }
}
```

---

### Mobile App Usage

Untuk mobile app, hanya perlu memanggil endpoint `GET /api/jam-absensi/active` untuk mendapatkan jam kerja yang berlaku:

```dart
// Flutter example
final response = await http.get(
  Uri.parse('$baseUrl/api/jam-absensi/active'),
  headers: {'Authorization': 'Bearer $token'},
);

final data = jsonDecode(response.body);
if (data['rcode'] == '00') {
  final jamKerja = data['data'];
  print('Jam masuk: ${jamKerja['start_jam_masuk']} - ${jamKerja['end_jam_masuk']}');
  print('Jam pulang: ${jamKerja['start_jam_pulang']} - ${jamKerja['end_jam_pulang']}');
}
```

---

## Device Reset

### 6. Request Reset Device

User mengajukan permohonan reset device (ketika ganti HP).

**Endpoint:** `POST /api/device-reset/request`  
**Auth Required:** No (user mungkin tidak bisa login)

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| npp | string | Yes | NPP karyawan |
| reason | string | Yes | Alasan reset (min 10 karakter) |

#### Request Example

```json
{
    "npp": "10001",
    "reason": "Handphone rusak dan sudah diganti dengan yang baru"
}
```

#### Response Success (201)

```json
{
    "rcode": "00",
    "message": "Permintaan reset device berhasil diajukan. Mohon tunggu approval dari admin.",
    "data": {
        "id": 1,
        "npp": "10001",
        "old_device_id": "abc123-old-device",
        "reason": "Handphone rusak dan sudah diganti dengan yang baru",
        "status": "pending",
        "created_at": "2026-01-30T10:00:00.000000Z"
    }
}
```

#### Response Errors

| rcode | Message | Description |
|-------|---------|-------------|
| 81 | User tidak ditemukan | NPP tidak valid |
| 82 | Anda sudah memiliki permintaan reset device yang sedang diproses | Ada request pending |

---

### 7. Cek Status Request Reset Device

Melihat status permohonan reset device.

**Endpoint:** `POST /api/device-reset/my-request`  
**Auth Required:** No

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| npp | string | Yes | NPP karyawan |

#### Request Example

```json
{
    "npp": "10001"
}
```

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "Success",
    "data": [
        {
            "id": 1,
            "npp": "10001",
            "old_device_id": "abc123-old-device",
            "reason": "Handphone rusak",
            "status": "approved",
            "processed_by": "admin",
            "processed_at": "2026-01-30T12:00:00.000000Z",
            "admin_notes": null,
            "created_at": "2026-01-30T10:00:00.000000Z"
        }
    ]
}
```

**Status Values:**
- `pending` - Menunggu approval
- `approved` - Disetujui, bisa login dengan device baru
- `rejected` - Ditolak

---

## Blog/Berita

### 8. Get Daftar Blog Published

Mengambil daftar berita/pengumuman yang dipublish.

**Endpoint:** `GET /api/blogs/published`  
**Auth Required:** Yes (Bearer Token)

#### Query Parameters

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| category | string | No | Filter kategori: announcement, news, event, info, other |
| limit | int | No | Jumlah data (default: 10) |

#### Request Example

```
GET /api/blogs/published?category=announcement&limit=5
```

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "Success",
    "data": [
        {
            "id": 1,
            "title": "Pengumuman Libur Tahun Baru",
            "slug": "pengumuman-libur-tahun-baru",
            "excerpt": "Diberitahukan kepada seluruh karyawan...",
            "image_thumbnail": "blogs/thumbnail-1.jpg",
            "category": "announcement",
            "is_featured": true,
            "is_pinned": true,
            "published_at": "2026-01-15T08:00:00.000000Z",
            "view_count": 150
        }
    ]
}
```

---

### 9. Get Featured Blogs

Mengambil blog yang ditampilkan di banner/carousel.

**Endpoint:** `GET /api/blogs/featured`  
**Auth Required:** Yes (Bearer Token)

#### Query Parameters

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| limit | int | No | Jumlah data (default: 5) |

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "Success",
    "data": [
        {
            "id": 1,
            "title": "Update Aplikasi Absensi v2.0",
            "slug": "update-aplikasi-absensi-v2",
            "excerpt": "Versi terbaru sudah tersedia...",
            "image": "blogs/banner-1.jpg",
            "image_thumbnail": "blogs/thumbnail-1.jpg",
            "category": "news",
            "published_at": "2026-01-20T10:00:00.000000Z"
        }
    ]
}
```

---

### 10. Get Detail Blog

Mengambil detail lengkap blog.

**Endpoint:** `GET /api/blogs/{id}`  
**Auth Required:** Yes (Bearer Token)

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "Success",
    "data": {
        "id": 1,
        "title": "Pengumuman Libur Tahun Baru",
        "slug": "pengumuman-libur-tahun-baru",
        "excerpt": "Diberitahukan kepada seluruh karyawan...",
        "content": "<p>Dengan hormat, diberitahukan kepada seluruh karyawan...</p>",
        "image": "blogs/image-1.jpg",
        "image_thumbnail": "blogs/thumbnail-1.jpg",
        "category": "announcement",
        "status": "published",
        "is_featured": true,
        "is_pinned": true,
        "author_name": "Admin HRD",
        "published_at": "2026-01-15T08:00:00.000000Z",
        "view_count": 151,
        "created_at": "2026-01-15T07:00:00.000000Z"
    }
}
```

---

### 11. Get Blog by Slug

Mengambil detail blog berdasarkan slug (untuk deep linking).

**Endpoint:** `GET /api/blogs/slug/{slug}`  
**Auth Required:** Yes (Bearer Token)

#### Request Example

```
GET /api/blogs/slug/pengumuman-libur-tahun-baru
```

---

## Notifikasi

### 12. Get Daftar Notifikasi

Mengambil daftar notifikasi user.

**Endpoint:** `GET /api/notifications`  
**Auth Required:** Yes (Bearer Token)

#### Query Parameters

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| npp | string | Yes | NPP karyawan |
| is_read | string | No | Filter: "true" atau "false" |
| type | string | No | Filter tipe notifikasi |
| per_page | int | No | Jumlah per halaman (default: 20) |

#### Request Example

```
GET /api/notifications?npp=10001&is_read=false
```

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "Success",
    "data": {
        "current_page": 1,
        "data": [
            {
                "id": 1,
                "npp": "10001",
                "type": "reminder",
                "title": "Reminder Absen",
                "body": "Jangan lupa absen masuk hari ini!",
                "is_read": false,
                "read_at": null,
                "created_at": "2026-01-30T07:00:00.000000Z"
            }
        ],
        "total": 10,
        "per_page": 20
    }
}
```

---

### 13. Get Unread Count

Mengambil jumlah notifikasi yang belum dibaca.

**Endpoint:** `GET /api/notifications/unread-count`  
**Auth Required:** Yes (Bearer Token)

#### Query Parameters

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| npp | string | Yes | NPP karyawan |

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "Success",
    "unread_count": 5
}
```

---

### 14. Mark Notification as Read

Menandai notifikasi sebagai sudah dibaca.

**Endpoint:** `POST /api/notifications/{id}/read`  
**Auth Required:** Yes (Bearer Token)

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "Notification marked as read"
}
```

---

### 15. Mark All Notifications as Read

Menandai semua notifikasi sebagai sudah dibaca.

**Endpoint:** `POST /api/notifications/read-all`  
**Auth Required:** Yes (Bearer Token)

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| npp | string | Yes | NPP karyawan |

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "All notifications marked as read",
    "updated_count": 5
}
```

---

### 16. Register FCM Token

Mendaftarkan token FCM untuk push notification.

**Endpoint:** `POST /api/fcm/register`  
**Auth Required:** Yes (Bearer Token)

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| npp | string | Yes | NPP karyawan |
| fcm_token | string | Yes | Firebase Cloud Messaging token |
| device_type | string | No | Tipe device: "android" atau "ios" |
| device_id | string | No | Unique device identifier |

#### Request Example

```json
{
    "npp": "10001",
    "fcm_token": "cKPLxxxxxx:APA91bHxxxxx...",
    "device_type": "android",
    "device_id": "abc123-device-xyz"
}
```

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "FCM token registered successfully",
    "data": {
        "id": 1,
        "npp": "10001",
        "fcm_token": "cKPLxxxxxx:APA91bHxxxxx...",
        "device_type": "android",
        "device_id": "abc123-device-xyz",
        "is_active": true
    }
}
```

---

### 17. Unregister FCM Token

Menonaktifkan token FCM (saat logout).

**Endpoint:** `POST /api/fcm/unregister`  
**Auth Required:** Yes (Bearer Token)

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| fcm_token | string | Yes | Firebase Cloud Messaging token |

#### Response Success (200)

```json
{
    "rcode": "00",
    "message": "FCM token unregistered"
}
```

---

## Response Codes

### Standard Response Format

Semua response mengikuti format standar:

```json
{
    "rcode": "00",
    "message": "Success message",
    "data": { ... }
}
```

### Response Code Reference

| rcode | Description |
|-------|-------------|
| 00 | Success |
| 01 | Validation Error |
| 81 | Not Found |
| 82 | Duplicate/Conflict |
| 83 | Business Rule Violation |
| 99 | Server Error |

---

## Error Handling

### Validation Error (422)

```json
{
    "rcode": "01",
    "message": "Validation failed",
    "errors": {
        "latitude": ["Latitude is required for location verification"],
        "longitude": ["Longitude is required for location verification"]
    }
}
```

### Not Found Error (404)

```json
{
    "rcode": "81",
    "message": "Resource not found"
}
```

### Server Error (500)

```json
{
    "rcode": "99",
    "message": "Error: Internal server error message"
}
```

### Unauthorized (401)

Jika token expired atau tidak valid:

```json
{
    "message": "Token not provided" 
}
```

atau

```json
{
    "message": "Token is expired"
}
```

---

## Contoh Flow Penggunaan

### Flow Login dan Absen Masuk

```
1. POST /api/login
   -> Dapat access_token

2. POST /api/kantor (dengan Bearer token)
   -> Dapat koordinat dan radius kantor

3. Validasi GPS user dengan koordinat kantor

4. POST /api/absenmasuk (dengan Bearer token)
   -> Absen masuk berhasil
```

### Flow Reset Device

```
1. User tidak bisa login (device berbeda)
   -> Response: "Device Tidak Sesuai..."

2. POST /api/device-reset/request
   -> Request reset berhasil disubmit

3. POST /api/device-reset/my-request
   -> Cek status: pending/approved/rejected

4. Jika approved, user bisa login dengan device baru
```

---

## Catatan Penting

1. **NPP dari Token**: Untuk endpoint absensi, NPP diambil dari JWT token. Jika dikirim di body, akan diabaikan (untuk keamanan).

2. **Device Binding**: Satu device hanya bisa digunakan oleh satu user. Untuk ganti device, gunakan fitur Device Reset.

3. **Caching**: Data kantor di-cache selama 24 jam untuk performa. Jika ada perubahan lokasi kantor, hubungi admin.

4. **Image URL**: Untuk field image, tambahkan base URL storage: `https://your-domain.com/storage/{image_path}`

---

**Dokumentasi ini diperbarui secara berkala. Untuk pertanyaan, hubungi tim development.**
