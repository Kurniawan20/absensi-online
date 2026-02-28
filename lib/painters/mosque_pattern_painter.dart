import 'package:flutter/material.dart';
import 'dart:math' as math;

/// CustomPainter bertema Ramadhan dengan siluet kubah masjid dan menara
class MosquePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Gambar bintang-bintang di langit
    _drawSkyStars(canvas, size, paint);

    // Gambar bulan sabit besar
    _drawCrescent(canvas, size, paint);

    // Gambar siluet masjid di bagian bawah
    _drawMosqueSilhouette(canvas, size, paint);
  }

  /// Menggambar bintang kecil di langit
  void _drawSkyStars(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.white.withValues(alpha: 0.18);
    final stars = [
      [0.10, 0.10, 2.5],
      [0.25, 0.05, 3.0],
      [0.42, 0.12, 2.0],
      [0.58, 0.08, 3.5],
      [0.75, 0.15, 2.0],
      [0.90, 0.06, 2.8],
      [0.15, 0.25, 1.8],
      [0.50, 0.22, 2.2],
      [0.82, 0.28, 1.5],
      [0.35, 0.30, 2.0],
      [0.68, 0.18, 1.8],
    ];

    for (final star in stars) {
      final center = Offset(size.width * star[0], size.height * star[1]);
      _drawStarShape(canvas, center, star[2], paint);
    }
  }

  /// Menggambar bentuk bintang 6 sudut
  void _drawStarShape(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 12; i++) {
      final angle = (i * math.pi / 6) - math.pi / 2;
      final radius = (i % 2 == 0) ? r : r * 0.4;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  /// Menggambar bulan sabit di pojok kanan atas
  void _drawCrescent(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.white.withValues(alpha: 0.20);
    final center = Offset(size.width * 0.85, size.height * 0.12);
    const radius = 20.0;

    final outer = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final inner = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(center.dx + radius * 0.35, center.dy - radius * 0.1),
        radius: radius * 0.78,
      ));

    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, inner),
      paint,
    );
  }

  /// Menggambar siluet masjid di bagian bawah dengan bentuk yang lebih indah dan rapi
  void _drawMosqueSilhouette(Canvas canvas, Size size, Paint paint) {
    paint.color =
        Colors.white.withValues(alpha: 0.15); // Warna bayangan yang elegan

    final path = Path();
    final bottom = size.height;
    final w = size.width;

    // Mulai dari pojok kiri bawah
    path.moveTo(0, bottom);
    path.lineTo(0, bottom * 0.82);

    // --- Bangunan Sayap Kiri ---
    path.lineTo(w * 0.10, bottom * 0.82);

    // --- Menara Kiri ---
    // Dasar menara
    path.lineTo(w * 0.10, bottom * 0.55);
    // Balkon 1
    path.lineTo(w * 0.08, bottom * 0.55);
    path.lineTo(w * 0.08, bottom * 0.53);
    path.lineTo(w * 0.105, bottom * 0.53);
    // Tiang atas
    path.lineTo(w * 0.11, bottom * 0.45);
    // Balkon 2
    path.lineTo(w * 0.09, bottom * 0.45);
    path.lineTo(w * 0.09, bottom * 0.43);
    path.lineTo(w * 0.115, bottom * 0.43);
    // Kubah menara runcing
    path.quadraticBezierTo(
        w * 0.12, bottom * 0.38, w * 0.125, bottom * 0.32); // Puncak menara
    path.quadraticBezierTo(w * 0.13, bottom * 0.38, w * 0.135, bottom * 0.43);
    // Turun dari balkon 2
    path.lineTo(w * 0.16, bottom * 0.43);
    path.lineTo(w * 0.16, bottom * 0.45);
    path.lineTo(w * 0.14, bottom * 0.45);
    // Turun dari balkon 1
    path.lineTo(w * 0.145, bottom * 0.53);
    path.lineTo(w * 0.17, bottom * 0.53);
    path.lineTo(w * 0.17, bottom * 0.55);
    path.lineTo(w * 0.15, bottom * 0.55);
    // Turun dari dasar menara
    path.lineTo(w * 0.15, bottom * 0.82);

    // --- Bangunan Kiri menuju Kubah ---
    path.lineTo(w * 0.22, bottom * 0.82);
    path.lineTo(w * 0.22, bottom * 0.70);

    // --- Kubah Kiri ---
    _drawOnionDome(path, w * 0.22, bottom * 0.70, w * 0.16, bottom * 0.18);

    path.lineTo(w * 0.38, bottom * 0.70);
    path.lineTo(w * 0.38, bottom * 0.65);

    // --- Kubah Utama (Tengah) ---
    _drawOnionDome(path, w * 0.38, bottom * 0.65, w * 0.24, bottom * 0.32);

    // --- Bangunan Kanan menuju Kubah ---
    path.lineTo(w * 0.62, bottom * 0.65);
    path.lineTo(w * 0.62, bottom * 0.70);

    // --- Kubah Kanan ---
    _drawOnionDome(path, w * 0.62, bottom * 0.70, w * 0.16, bottom * 0.18);

    path.lineTo(w * 0.78, bottom * 0.70);
    path.lineTo(w * 0.78, bottom * 0.82);

    // --- Menara Kanan ---
    // Dasar menara
    path.lineTo(w * 0.85, bottom * 0.82);
    path.lineTo(w * 0.85, bottom * 0.55);
    // Balkon 1
    path.lineTo(w * 0.83, bottom * 0.55);
    path.lineTo(w * 0.83, bottom * 0.53);
    path.lineTo(w * 0.855, bottom * 0.53);
    // Tiang atas
    path.lineTo(w * 0.86, bottom * 0.45);
    // Balkon 2
    path.lineTo(w * 0.84, bottom * 0.45);
    path.lineTo(w * 0.84, bottom * 0.43);
    path.lineTo(w * 0.865, bottom * 0.43);
    // Kubah menara runcing
    path.quadraticBezierTo(
        w * 0.87, bottom * 0.38, w * 0.875, bottom * 0.32); // Puncak menara
    path.quadraticBezierTo(w * 0.88, bottom * 0.38, w * 0.885, bottom * 0.43);
    // Turun dari balkon 2
    path.lineTo(w * 0.91, bottom * 0.43);
    path.lineTo(w * 0.91, bottom * 0.45);
    path.lineTo(w * 0.89, bottom * 0.45);
    // Turun dari balkon 1
    path.lineTo(w * 0.895, bottom * 0.53);
    path.lineTo(w * 0.92, bottom * 0.53);
    path.lineTo(w * 0.92, bottom * 0.55);
    path.lineTo(w * 0.90, bottom * 0.55);
    // Turun dari dasar menara
    path.lineTo(w * 0.90, bottom * 0.82);

    // --- Bangunan Sayap Kanan ---
    path.lineTo(w, bottom * 0.82);
    path.lineTo(w, bottom);

    path.close();
    canvas.drawPath(path, paint);

    // Tambahkan detail jendela dan pintu agar lebih realistis
    _drawMosqueDetails(canvas, size, paint);
  }

  /// Menggambar bentuk kubah bawang ganda khas arsitektur timur tengah
  void _drawOnionDome(
      Path path, double startX, double startY, double width, double height) {
    final endX = startX + width;
    final topY = startY - height;
    final midX = startX + width / 2;

    // Sisi kiri kubah (mengembang keluar, lalu mengerucut ke atas)
    path.cubicTo(startX - width * 0.15, startY - height * 0.4,
        midX - width * 0.15, topY + height * 0.2, midX, topY);

    // Sisi kanan kubah
    path.cubicTo(midX + width * 0.15, topY + height * 0.2, endX + width * 0.15,
        startY - height * 0.4, endX, startY);
  }

  /// Menggambar detail pintu dan jendela melengkung
  void _drawMosqueDetails(Canvas canvas, Size size, Paint paint) {
    // Warna untuk jendela dan pintu (membuat lubang cahaya/detail)
    paint
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final bottom = size.height;
    final w = size.width;

    // --- Pintu Utama di Bawah Kubah Tengah ---
    _drawArchWindow(canvas, Offset(w * 0.50, bottom * 0.77), w * 0.05,
        bottom * 0.10, paint);

    // --- Jendela Bangunan Utama ---
    _drawArchWindow(canvas, Offset(w * 0.41, bottom * 0.77), w * 0.02,
        bottom * 0.06, paint);
    _drawArchWindow(canvas, Offset(w * 0.59, bottom * 0.77), w * 0.02,
        bottom * 0.06, paint);

    // --- Jendela di Dalam Kubah Tengah ---
    _drawArchWindow(canvas, Offset(w * 0.44, bottom * 0.58), w * 0.02,
        bottom * 0.06, paint);
    _drawArchWindow(canvas, Offset(w * 0.50, bottom * 0.55), w * 0.025,
        bottom * 0.08, paint);
    _drawArchWindow(canvas, Offset(w * 0.56, bottom * 0.58), w * 0.02,
        bottom * 0.06, paint);

    // --- Jendela di Dalam Kubah Kiri ---
    _drawArchWindow(canvas, Offset(w * 0.30, bottom * 0.64), w * 0.018,
        bottom * 0.05, paint);

    // --- Jendela di Dalam Kubah Kanan ---
    _drawArchWindow(canvas, Offset(w * 0.70, bottom * 0.64), w * 0.018,
        bottom * 0.05, paint);

    // --- Jendela Sayap Kiri ---
    _drawArchWindow(canvas, Offset(w * 0.03, bottom * 0.78), w * 0.015,
        bottom * 0.04, paint);
    _drawArchWindow(canvas, Offset(w * 0.07, bottom * 0.78), w * 0.015,
        bottom * 0.04, paint);

    // --- Jendela Sayap Kanan ---
    _drawArchWindow(canvas, Offset(w * 0.93, bottom * 0.78), w * 0.015,
        bottom * 0.04, paint);
    _drawArchWindow(canvas, Offset(w * 0.97, bottom * 0.78), w * 0.015,
        bottom * 0.04, paint);

    // --- Jendela Menara Kiri ---
    _drawArchWindow(canvas, Offset(w * 0.125, bottom * 0.50), w * 0.01,
        bottom * 0.03, paint);
    _drawArchWindow(canvas, Offset(w * 0.125, bottom * 0.60), w * 0.015,
        bottom * 0.04, paint);
    _drawArchWindow(canvas, Offset(w * 0.125, bottom * 0.70), w * 0.015,
        bottom * 0.04, paint);

    // --- Jendela Menara Kanan ---
    _drawArchWindow(canvas, Offset(w * 0.875, bottom * 0.50), w * 0.01,
        bottom * 0.03, paint);
    _drawArchWindow(canvas, Offset(w * 0.875, bottom * 0.60), w * 0.015,
        bottom * 0.04, paint);
    _drawArchWindow(canvas, Offset(w * 0.875, bottom * 0.70), w * 0.015,
        bottom * 0.04, paint);
  }

  /// Menggambar jendela melengkung khas Islami (Moorish Arch)
  void _drawArchWindow(Canvas canvas, Offset center, double halfWidth,
      double height, Paint paint) {
    final path = Path();
    final top = center.dy - height / 2;
    final bot = center.dy + height / 2;
    final left = center.dx - halfWidth;
    final right = center.dx + halfWidth;

    // Sisi kiri
    path.moveTo(left, bot);
    path.lineTo(left, top + halfWidth);

    // Lengkungan Moorish (melengkung keluar sedikit lalu meruncing ke atas)
    path.cubicTo(left - halfWidth * 0.2, top, center.dx, top - halfWidth * 0.6,
        center.dx, top - halfWidth * 1.2);
    path.cubicTo(center.dx, top - halfWidth * 0.6, right + halfWidth * 0.2, top,
        right, top + halfWidth);

    // Sisi kanan
    path.lineTo(right, bot);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
