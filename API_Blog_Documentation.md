# Blog API Documentation

## Overview

API untuk mengelola Blog/Berita di aplikasi Absensi Mobile. Mendukung CRUD operasi, upload gambar, dan multiple document attachments.

---

## Base URL

```
Development: http://localhost:8000/api
Production: https://api.yourdomain.com/api
```

---

## Authentication

Semua endpoint membutuhkan JWT Bearer Token (kecuali public endpoints).

```
Authorization: Bearer <your_jwt_token>
```

---

## Endpoints

### 1. Get Published Blogs (Mobile)

Mengambil daftar blog yang sudah dipublish untuk ditampilkan di mobile app.

**Endpoint:** `GET /blogs/published`

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| category | string | No | Filter by category: `announcement`, `news`, `event`, `info`, `other` |
| limit | int | No | Jumlah data (default: 10) |

**Response:**

```json
{
  "rcode": "00",
  "message": "Success",
  "data": [
    {
      "id": 1,
      "title": "Pengumuman Libur Lebaran 2026",
      "slug": "pengumuman-libur-lebaran-2026",
      "excerpt": "Diberitahukan kepada seluruh karyawan...",
      "image_thumbnail": "blogs/pengumuman-libur-1234567890.jpg",
      "category": "announcement",
      "is_featured": true,
      "is_pinned": true,
      "published_at": "2026-02-05T10:00:00.000000Z",
      "view_count": 150
    }
  ]
}
```

---

### 2. Get Featured Blogs (Mobile Dashboard)

Mengambil blog featured untuk carousel/banner di dashboard.

**Endpoint:** `GET /blogs/featured`

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| limit | int | No | Jumlah data (default: 5) |

**Response:**

```json
{
  "rcode": "00",
  "message": "Success",
  "data": [
    {
      "id": 1,
      "title": "Pengumuman Libur Lebaran 2026",
      "slug": "pengumuman-libur-lebaran-2026",
      "excerpt": "Diberitahukan kepada seluruh karyawan...",
      "image": "blogs/pengumuman-libur-1234567890.jpg",
      "image_thumbnail": "blogs/pengumuman-libur-1234567890.jpg",
      "category": "announcement",
      "published_at": "2026-02-05T10:00:00.000000Z"
    }
  ]
}
```

---

### 3. Get Blog by Slug (Mobile Deep Linking)

Mengambil detail blog berdasarkan slug (untuk deep linking dari push notification).

**Endpoint:** `GET /blogs/slug/{slug}`

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| slug | string | Yes | Blog slug |

**Response:**

```json
{
  "rcode": "00",
  "message": "Success",
  "data": {
    "id": 1,
    "title": "Pengumuman Libur Lebaran 2026",
    "slug": "pengumuman-libur-lebaran-2026",
    "excerpt": "Diberitahukan kepada seluruh karyawan...",
    "content": "<p>Full HTML content here...</p>",
    "image": "blogs/pengumuman-libur-1234567890.jpg",
    "image_thumbnail": "blogs/pengumuman-libur-1234567890.jpg",
    "category": "announcement",
    "status": "published",
    "is_featured": true,
    "is_pinned": true,
    "author_npp": "10005",
    "author_name": "Admin HR",
    "view_count": 151,
    "published_at": "2026-02-05T10:00:00.000000Z",
    "created_at": "2026-02-05T09:00:00.000000Z",
    "updated_at": "2026-02-05T10:00:00.000000Z",
    "attachments": [
      {
        "id": 1,
        "file_name": "Surat_Edaran_Libur.pdf",
        "file_path": "blog-attachments/pengumuman-libur-1234567890-abc123.pdf",
        "file_type": "pdf",
        "file_size": 1024000,
        "file_size_human": "1.00 MB",
        "file_icon": "file-pdf",
        "download_url": "http://localhost/storage/blog-attachments/pengumuman-libur-1234567890-abc123.pdf",
        "description": null,
        "created_at": "2026-02-05T09:00:00.000000Z"
      }
    ]
  }
}
```

---

### 4. Get All Blogs (Admin Dashboard)

Mengambil semua blog dengan pagination untuk admin dashboard.

**Endpoint:** `GET /blogs`

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| status | string | No | Filter: `draft`, `published`, `archived` |
| category | string | No | Filter by category |
| is_featured | string | No | Filter: `true` or `false` |
| search | string | No | Search in title and content |
| per_page | int | No | Items per page (default: 20) |
| page | int | No | Page number |

**Response:**

```json
{
  "rcode": "00",
  "message": "Success",
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        "title": "Pengumuman Libur Lebaran 2026",
        "slug": "pengumuman-libur-lebaran-2026",
        "excerpt": "Diberitahukan kepada seluruh karyawan...",
        "content": "<p>Full content...</p>",
        "image": "blogs/pengumuman-libur.jpg",
        "category": "announcement",
        "status": "published",
        "is_featured": true,
        "is_pinned": true,
        "view_count": 150,
        "published_at": "2026-02-05T10:00:00.000000Z",
        "created_at": "2026-02-05T09:00:00.000000Z"
      }
    ],
    "first_page_url": "http://localhost/api/blogs?page=1",
    "from": 1,
    "last_page": 5,
    "last_page_url": "http://localhost/api/blogs?page=5",
    "next_page_url": "http://localhost/api/blogs?page=2",
    "path": "http://localhost/api/blogs",
    "per_page": 20,
    "prev_page_url": null,
    "to": 20,
    "total": 100
  }
}
```

---

### 5. Get Blog Detail (Admin Dashboard)

Mengambil detail blog berdasarkan ID.

**Endpoint:** `GET /blogs/{id}`

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | int | Yes | Blog ID |

**Response:** Same as Get Blog by Slug

---

### 6. Create Blog (Admin Dashboard)

Membuat blog baru dengan optional image dan attachments.

**Endpoint:** `POST /blogs`

**Content-Type:** `multipart/form-data`

**Body Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| title | string | Yes | Judul blog (max 255 chars) |
| content | string | Yes | Konten HTML |
| excerpt | string | No | Ringkasan (max 500 chars, auto-generated if empty) |
| category | string | No | `announcement`, `news`, `event`, `info`, `other` (default: `news`) |
| status | string | No | `draft`, `published`, `archived` (default: `draft`) |
| is_featured | boolean | No | Tampilkan di featured (default: false) |
| is_pinned | boolean | No | Pin di atas list (default: false) |
| author_npp | string | No | NPP author |
| author_name | string | No | Nama author |
| send_notification | boolean | No | Kirim push notification jika published (default: true) |
| image | file | No | Gambar utama (jpeg, png, jpg, gif, max 2MB) |
| attachments[] | file[] | No | Document attachments (pdf, doc, docx, xls, xlsx, max 10MB each, max 10 files) |

**Example Request (cURL):**

```bash
curl -X POST http://localhost:8000/api/blogs \
  -H "Authorization: Bearer <token>" \
  -F "title=Pengumuman Penting" \
  -F "content=<p>Isi pengumuman penting...</p>" \
  -F "excerpt=Ringkasan pengumuman" \
  -F "category=announcement" \
  -F "status=published" \
  -F "is_featured=true" \
  -F "is_pinned=false" \
  -F "author_npp=10005" \
  -F "author_name=Admin HR" \
  -F "send_notification=true" \
  -F "image=@/path/to/image.jpg" \
  -F "attachments[0]=@/path/to/surat_edaran.pdf" \
  -F "attachments[1]=@/path/to/lampiran.docx"
```

**Example Request (Dart/Flutter):**

```dart
import 'package:dio/dio.dart';

Future<void> createBlog() async {
  final dio = Dio();
  dio.options.headers['Authorization'] = 'Bearer $token';

  final formData = FormData.fromMap({
    'title': 'Pengumuman Penting',
    'content': '<p>Isi pengumuman...</p>',
    'category': 'announcement',
    'status': 'published',
    'is_featured': true,
    'image': await MultipartFile.fromFile('/path/to/image.jpg'),
    'attachments[]': [
      await MultipartFile.fromFile('/path/to/doc1.pdf'),
      await MultipartFile.fromFile('/path/to/doc2.docx'),
    ],
  });

  final response = await dio.post('/api/blogs', data: formData);
  print(response.data);
}
```

**Example Request (JavaScript/Axios):**

```javascript
const formData = new FormData();
formData.append('title', 'Pengumuman Penting');
formData.append('content', '<p>Isi pengumuman...</p>');
formData.append('category', 'announcement');
formData.append('status', 'published');
formData.append('is_featured', true);
formData.append('image', imageFile);

// Multiple attachments
attachmentFiles.forEach((file, index) => {
  formData.append('attachments[]', file);
});

const response = await axios.post('/api/blogs', formData, {
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'multipart/form-data'
  }
});
```

**Response:**

```json
{
  "rcode": "00",
  "message": "Blog created successfully",
  "data": {
    "id": 1,
    "title": "Pengumuman Penting",
    "slug": "pengumuman-penting",
    "excerpt": "Ringkasan pengumuman",
    "content": "<p>Isi pengumuman penting...</p>",
    "image": "blogs/pengumuman-penting-1234567890.jpg",
    "image_thumbnail": "blogs/pengumuman-penting-1234567890.jpg",
    "category": "announcement",
    "status": "published",
    "is_featured": true,
    "is_pinned": false,
    "author_npp": "10005",
    "author_name": "Admin HR",
    "view_count": 0,
    "published_at": "2026-02-05T10:00:00.000000Z",
    "created_at": "2026-02-05T10:00:00.000000Z",
    "updated_at": "2026-02-05T10:00:00.000000Z",
    "attachments": [
      {
        "id": 1,
        "file_name": "surat_edaran.pdf",
        "file_path": "blog-attachments/pengumuman-penting-1234567890-abc123.pdf",
        "file_type": "pdf",
        "file_size": 1024000,
        "file_size_human": "1.00 MB",
        "file_icon": "file-pdf",
        "download_url": "http://localhost/storage/blog-attachments/pengumuman-penting-1234567890-abc123.pdf"
      },
      {
        "id": 2,
        "file_name": "lampiran.docx",
        "file_path": "blog-attachments/pengumuman-penting-1234567890-def456.docx",
        "file_type": "docx",
        "file_size": 512000,
        "file_size_human": "500.00 KB",
        "file_icon": "file-word",
        "download_url": "http://localhost/storage/blog-attachments/pengumuman-penting-1234567890-def456.docx"
      }
    ]
  },
  "attachments_uploaded": 2,
  "notification_sent": true,
  "notification_result": {
    "success": true,
    "message_id": "projects/haba-1f47f/messages/123456"
  }
}
```

---

### 7. Update Blog (Admin Dashboard)

Mengupdate blog yang sudah ada.

**Endpoint:** `PUT /blogs/{id}`

**Content-Type:** `multipart/form-data`

**Note:** Untuk update dengan file, gunakan `POST` dengan `_method=PUT` karena beberapa client tidak support file upload dengan PUT.

```bash
curl -X POST http://localhost:8000/api/blogs/1 \
  -H "Authorization: Bearer <token>" \
  -F "_method=PUT" \
  -F "title=Judul Baru" \
  -F "attachments[]=@/path/to/new_file.pdf"
```

**Body Parameters:** Same as Create (semua optional kecuali tidak bisa hapus field yang required)

**Response:**

```json
{
  "rcode": "00",
  "message": "Blog updated successfully",
  "data": { ... },
  "attachments_uploaded": 1
}
```

---

### 8. Delete Blog (Admin Dashboard)

Menghapus blog beserta semua attachments.

**Endpoint:** `DELETE /blogs/{id}`

**Response:**

```json
{
  "rcode": "00",
  "message": "Blog deleted successfully",
  "deleted_title": "Pengumuman Penting"
}
```

---

### 9. Publish Blog (Admin Dashboard)

Mempublish blog yang masih draft.

**Endpoint:** `POST /blogs/{id}/publish`

**Body Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| send_notification | boolean | No | Kirim push notification (default: true) |

**Response:**

```json
{
  "rcode": "00",
  "message": "Blog published successfully",
  "data": { ... },
  "notification_sent": true,
  "notification_result": { ... }
}
```

---

### 10. Archive Blog (Admin Dashboard)

Mengarsipkan blog.

**Endpoint:** `POST /blogs/{id}/archive`

**Response:**

```json
{
  "rcode": "00",
  "message": "Blog archived successfully",
  "data": { ... }
}
```

---

### 11. Add Attachments to Existing Blog (Admin Dashboard)

Menambahkan attachments ke blog yang sudah ada.

**Endpoint:** `POST /blogs/{id}/attachments`

**Content-Type:** `multipart/form-data`

**Body Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| attachments[] | file[] | Yes | Document files (pdf, doc, docx, xls, xlsx, max 10MB each, max 10 files) |

**Example Request:**

```bash
curl -X POST http://localhost:8000/api/blogs/1/attachments \
  -H "Authorization: Bearer <token>" \
  -F "attachments[0]=@/path/to/file1.pdf" \
  -F "attachments[1]=@/path/to/file2.xlsx"
```

**Response:**

```json
{
  "rcode": "00",
  "message": "Attachments uploaded successfully",
  "attachments_uploaded": 2,
  "data": [
    {
      "id": 3,
      "file_name": "file1.pdf",
      "file_path": "blog-attachments/xxx.pdf",
      "file_type": "pdf",
      "file_size": 2048000,
      "file_size_human": "2.00 MB",
      "file_icon": "file-pdf",
      "download_url": "http://localhost/storage/blog-attachments/xxx.pdf"
    },
    {
      "id": 4,
      "file_name": "file2.xlsx",
      "file_path": "blog-attachments/xxx.xlsx",
      "file_type": "xlsx",
      "file_size": 512000,
      "file_size_human": "500.00 KB",
      "file_icon": "file-excel",
      "download_url": "http://localhost/storage/blog-attachments/xxx.xlsx"
    }
  ]
}
```

---

### 12. Delete Attachment (Admin Dashboard)

Menghapus attachment tertentu.

**Endpoint:** `DELETE /blogs/attachments/{id}`

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | int | Yes | Attachment ID |

**Response:**

```json
{
  "rcode": "00",
  "message": "Attachment deleted successfully",
  "deleted_file": "surat_edaran.pdf"
}
```

---

## Error Responses

### Validation Error (422)

```json
{
  "rcode": "01",
  "message": "Validation error",
  "errors": {
    "title": ["The title field is required."],
    "attachments.0": ["The attachments.0 must be a file of type: pdf, doc, docx, xls, xlsx."]
  }
}
```

### Not Found (404)

```json
{
  "rcode": "81",
  "message": "Blog not found"
}
```

### Server Error (500)

```json
{
  "rcode": "99",
  "message": "Error: <error_message>"
}
```

---

## Categories

| Value | Display Name |
|-------|--------------|
| `announcement` | Pengumuman |
| `news` | Berita |
| `event` | Event |
| `info` | Informasi |
| `other` | Lainnya |

---

## Status

| Value | Description |
|-------|-------------|
| `draft` | Belum dipublish, tidak muncul di mobile |
| `published` | Sudah dipublish, muncul di mobile |
| `archived` | Diarsipkan, tidak muncul di mobile |

---

## Attachment Icons

| File Type | Icon Name | Description |
|-----------|-----------|-------------|
| `pdf` | `file-pdf` | PDF Document |
| `doc`, `docx` | `file-word` | Word Document |
| `xls`, `xlsx` | `file-excel` | Excel Spreadsheet |

---

## Push Notification Payload

Ketika blog dipublish, push notification dikirim dengan payload:

```json
{
  "notification": {
    "title": "Pengumuman Penting",
    "body": "Ringkasan pengumuman..."
  },
  "data": {
    "type": "news",
    "blog_id": "1",
    "blog_slug": "pengumuman-penting",
    "category": "announcement",
    "image": "blogs/pengumuman-penting.jpg"
  }
}
```

### Handling di Flutter

```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  final data = message.data;
  
  if (data['type'] == 'news' || data['type'] == 'announcement') {
    // Navigate to blog detail
    Navigator.pushNamed(
      context, 
      '/blog-detail',
      arguments: {
        'blog_id': data['blog_id'],
        'blog_slug': data['blog_slug'],
      },
    );
  }
});
```

---

## File Size Limits

| Type | Max Size | Allowed Extensions |
|------|----------|-------------------|
| Image | 2 MB | jpeg, png, jpg, gif |
| Attachment | 10 MB | pdf, doc, docx, xls, xlsx |
| Max Attachments per Blog | 10 files | - |

---

## Image URLs

Semua image dan attachment URLs menggunakan format:

```
{base_url}/storage/{file_path}
```

Example:
```
http://localhost:8000/storage/blogs/pengumuman-penting-1234567890.jpg
http://localhost:8000/storage/blog-attachments/xxx.pdf
```

Pastikan symlink sudah dibuat:
```bash
php artisan storage:link
```
