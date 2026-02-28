# App Version Management — Panduan Mobile

**Base URL:** `http://{host}:{port}/api`  
**Auth:** Tidak perlu token (endpoint publik)

---

## Alur Version Check

```
App Startup
    │
    ▼
POST /app-version/check
    │
    ├── maintenance_mode = true  →  🚧 Tampilkan halaman maintenance (block total)
    │
    ├── force_update = true      →  🔒 Paksa ke Store (tidak bisa skip)
    │
    ├── needs_update = true      →  💡 Dialog update opsional (bisa skip)
    │
    └── Semua false              →  ✅ Lanjut ke Login
```

> **Penting:** Endpoint ini harus dipanggil **pertama kali** saat app dibuka, **sebelum login**.

---

## Endpoints

### 1. `POST /app-version/check` ⭐ Utama

Cek apakah app perlu update atau sedang maintenance.

**Request:**
```json
{
    "platform": "android",
    "build_number": 5
}
```

| Field | Tipe | Wajib | Keterangan |
|---|---|---|---|
| `platform` | string | ✅ | `android` / `ios` |
| `build_number` | int | ✅ | Build number app saat ini |

**Header opsional:**
```
Accept-Language: id
```
> Menentukan bahasa pesan update (`id` / `en`). Default: `id`.

---

#### Response — Tidak ada update
```json
{
    "rcode": "00",
    "message": "Version check completed",
    "data": {
        "needs_update": false,
        "force_update": false,
        "maintenance_mode": false
    }
}
```
**Aksi mobile:** Lanjut ke login screen.

---

#### Response — Update opsional
```json
{
    "rcode": "00",
    "message": "Update available",
    "data": {
        "needs_update": true,
        "force_update": false,
        "maintenance_mode": false,
        "update_message": "Versi baru tersedia dengan fitur terbaru",
        "store_url": "https://play.google.com/store/apps/details?id=com.app",
        "changelog": "- Fitur notifikasi baru\n- Perbaikan bug"
    }
}
```
**Aksi mobile:** Tampilkan dialog dengan tombol **"Update"** + **"Nanti"**. User bisa skip.

---

#### Response — Force update (wajib)
```json
{
    "rcode": "00",
    "message": "Update required",
    "data": {
        "needs_update": true,
        "force_update": true,
        "maintenance_mode": false,
        "update_message": "Update wajib untuk keamanan aplikasi",
        "store_url": "https://play.google.com/store/apps/details?id=com.app",
        "changelog": "- Security patch penting"
    }
}
```
**Aksi mobile:** Tampilkan dialog **tanpa tombol close**. Hanya tombol **"Update Sekarang"** yang mengarah ke Store.

---

#### Response — Maintenance mode
```json
{
    "rcode": "00",
    "message": "App under maintenance",
    "data": {
        "needs_update": false,
        "force_update": false,
        "maintenance_mode": true,
        "maintenance_message": "Sedang perbaikan sistem, estimasi selesai pukul 14:00 WIB"
    }
}
```
**Aksi mobile:** Tampilkan halaman maintenance full screen. User **tidak bisa mengakses** fitur apapun.

---

### 2. `GET /app-version/latest/{platform}`

Informasi versi terbaru (tanpa pengecekan build number).

**Path:** `/app-version/latest/android` atau `/app-version/latest/ios`

**Response 200:**
```json
{
    "rcode": "00",
    "message": "Success",
    "data": {
        "platform": "android",
        "version_code": "1.0.3",
        "build_number": 6,
        "min_version_code": "1.0.0",
        "min_build_number": 1,
        "store_url": "https://play.google.com/...",
        "changelog": "- Fitur baru\n- Bug fixes",
        "maintenance_mode": false
    }
}
```

---

## Logika Pengecekan Server

Server membandingkan `build_number` dari mobile dengan konfigurasi:

| Kondisi | Hasil | Aksi Mobile |
|---|---|---|
| `maintenance_mode` aktif | Block total | Halaman maintenance |
| `build_number` < `min_build_number` | `force_update = true` | Paksa ke Store |
| `build_number` < `build_number` terbaru | `needs_update = true` | Dialog opsional |
| `build_number` >= terbaru | Semua false | Lanjut normal |

> Prioritas pengecekan: **Maintenance → Force Update → Update Opsional → OK**

---

## Contoh Implementasi Flutter

```dart
/// Panggil di main.dart atau splash screen sebelum navigasi ke login
Future<void> checkAppVersion(BuildContext context) async {
  try {
    final response = await dio.post('/app-version/check', data: {
      'platform': Platform.isAndroid ? 'android' : 'ios',
      'build_number': int.parse(packageInfo.buildNumber),
    });

    final data = response.data['data'];

    // 1. Cek maintenance
    if (data['maintenance_mode'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MaintenancePage(
          message: data['maintenance_message'],
        )),
      );
      return;
    }

    // 2. Cek force update
    if (data['force_update'] == true) {
      showDialog(
        context: context,
        barrierDismissible: false, // Tidak bisa dismiss
        builder: (_) => ForceUpdateDialog(
          message: data['update_message'],
          storeUrl: data['store_url'],
        ),
      );
      return;
    }

    // 3. Cek update opsional
    if (data['needs_update'] == true) {
      showDialog(
        context: context,
        builder: (_) => OptionalUpdateDialog(
          message: data['update_message'],
          storeUrl: data['store_url'],
          changelog: data['changelog'],
        ),
      );
      // User bisa dismiss, lanjut ke login
    }

    // 4. Lanjut ke login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );

  } catch (e) {
    // Jika API gagal, tetap lanjut ke login (graceful fallback)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }
}
```

---

## Konfigurasi dari Admin Dashboard

Admin mengatur versi melalui endpoint:

| Aksi | Endpoint | Keterangan |
|---|---|---|
| Lihat semua | `GET /app-versions` | List per platform |
| Update versi | `POST /app-versions` | Upsert per platform |
| Toggle force update | `POST /app-versions/{id}/toggle-force-update` | On/off paksa update |
| Toggle maintenance | `POST /app-versions/{id}/toggle-maintenance` | On/off maintenance |

> Detail lengkap ada di [API_ADMIN_DASHBOARD.md](./API_ADMIN_DASHBOARD.md#10-app-version-management).
