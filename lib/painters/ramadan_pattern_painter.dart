import 'package:flutter/material.dart';
import 'dart:math' as math;

/// CustomPainter bertema Ramadhan dengan motif bulan sabit, bintang, dan lentera
class RamadanPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Gambar bulan sabit di beberapa posisi
    _drawCrescents(canvas, size, paint);

    // Gambar bintang kecil tersebar
    _drawStars(canvas, size, paint);

    // Gambar siluet lentera
    _drawLanterns(canvas, size, paint);

    // Gambar pola geometris islami (hexagonal)
    _drawGeometricAccents(canvas, size, paint);
  }

  /// Menggambar bulan sabit di beberapa posisi
  void _drawCrescents(Canvas canvas, Size size, Paint paint) {
    final crescents = [
      Offset(size.width * 0.85, size.height * 0.15),
      Offset(size.width * 0.12, size.height * 0.75),
    ];
    final scales = [1.0, 0.6];

    for (int i = 0; i < crescents.length; i++) {
      _drawCrescent(
        canvas,
        crescents[i],
        18 * scales[i],
        paint..color = Colors.white.withValues(alpha: 0.18 + i * 0.04),
      );
    }
  }

  /// Menggambar satu bulan sabit
  void _drawCrescent(Canvas canvas, Offset center, double radius, Paint paint) {
    final outerCircle = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    // Lingkaran dalam digeser untuk membentuk sabit
    final innerCircle = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(center.dx + radius * 0.4, center.dy - radius * 0.1),
        radius: radius * 0.8,
      ));

    // Sabit = lingkaran luar dikurangi lingkaran dalam
    final crescent =
        Path.combine(PathOperation.difference, outerCircle, innerCircle);
    canvas.drawPath(crescent, paint);
  }

  /// Menggambar bintang-bintang kecil
  void _drawStars(Canvas canvas, Size size, Paint paint) {
    final starPositions = [
      Offset(size.width * 0.08, size.height * 0.12),
      Offset(size.width * 0.25, size.height * 0.08),
      Offset(size.width * 0.72, size.height * 0.06),
      Offset(size.width * 0.92, size.height * 0.35),
      Offset(size.width * 0.55, size.height * 0.15),
      Offset(size.width * 0.38, size.height * 0.22),
      Offset(size.width * 0.78, size.height * 0.28),
      Offset(size.width * 0.15, size.height * 0.40),
      Offset(size.width * 0.65, size.height * 0.45),
      Offset(size.width * 0.48, size.height * 0.65),
      Offset(size.width * 0.88, size.height * 0.60),
      Offset(size.width * 0.30, size.height * 0.80),
      Offset(size.width * 0.70, size.height * 0.78),
    ];
    final starSizes = [
      4.0,
      3.0,
      3.5,
      2.5,
      5.0,
      2.0,
      3.0,
      2.5,
      3.5,
      2.0,
      3.0,
      2.5,
      2.0
    ];

    for (int i = 0; i < starPositions.length; i++) {
      final opacity = 0.14 + (i % 3) * 0.05;
      _drawStar(
        canvas,
        starPositions[i],
        starSizes[i],
        paint..color = Colors.white.withValues(alpha: opacity),
      );
    }
  }

  /// Menggambar satu bintang bersudut 8
  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 8;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = (i % 2 == 0) ? radius : radius * 0.4;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  /// Menggambar siluet lentera
  void _drawLanterns(Canvas canvas, Size size, Paint paint) {
    _drawLantern(
      canvas,
      Offset(size.width * 0.18, size.height * 0.05),
      0.7,
      paint..color = Colors.white.withValues(alpha: 0.15),
    );
    _drawLantern(
      canvas,
      Offset(size.width * 0.82, size.height * 0.50),
      0.55,
      paint..color = Colors.white.withValues(alpha: 0.12),
    );
  }

  /// Menggambar satu lentera sederhana
  void _drawLantern(Canvas canvas, Offset top, double scale, Paint paint) {
    final w = 14.0 * scale;
    final h = 24.0 * scale;

    // Tali gantungan
    canvas.drawLine(
      top,
      Offset(top.dx, top.dy + 6 * scale),
      paint..strokeWidth = 1.5 * scale,
    );

    final bodyTop = Offset(top.dx, top.dy + 6 * scale);

    // Tutup atas lentera
    final capPath = Path()
      ..moveTo(bodyTop.dx - w * 0.4, bodyTop.dy)
      ..lineTo(bodyTop.dx + w * 0.4, bodyTop.dy)
      ..lineTo(bodyTop.dx + w * 0.3, bodyTop.dy + 3 * scale)
      ..lineTo(bodyTop.dx - w * 0.3, bodyTop.dy + 3 * scale)
      ..close();
    canvas.drawPath(capPath, paint..style = PaintingStyle.fill);

    // Badan lentera (bentuk oval/rounded rect)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(bodyTop.dx, bodyTop.dy + 3 * scale + h * 0.5),
        width: w,
        height: h,
      ),
      Radius.circular(w * 0.35),
    );
    canvas.drawRRect(bodyRect, paint);

    // Ujung bawah lentera
    final bottomPath = Path()
      ..moveTo(bodyTop.dx - w * 0.3, bodyTop.dy + 3 * scale + h)
      ..lineTo(bodyTop.dx + w * 0.3, bodyTop.dy + 3 * scale + h)
      ..lineTo(bodyTop.dx, bodyTop.dy + 3 * scale + h + 5 * scale)
      ..close();
    canvas.drawPath(bottomPath, paint);
  }

  /// Menggambar aksen geometris islami
  void _drawGeometricAccents(Canvas canvas, Size size, Paint paint) {
    paint
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Pola segi enam di sudut kanan bawah
    _drawHexagonCluster(
      canvas,
      Offset(size.width * 0.90, size.height * 0.85),
      12,
      paint,
    );

    // Pola segi enam di tengah kiri
    _drawHexagonCluster(
      canvas,
      Offset(size.width * 0.05, size.height * 0.55),
      10,
      paint,
    );

    // Reset style
    paint.style = PaintingStyle.fill;
  }

  /// Menggambar cluster segi enam (hexagon)
  void _drawHexagonCluster(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    // Hexagon utama
    _drawHexagon(canvas, center, radius, paint);

    // Hexagon di sekitarnya (6 arah)
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final offset = Offset(
        center.dx + radius * 1.8 * math.cos(angle),
        center.dy + radius * 1.8 * math.sin(angle),
      );
      _drawHexagon(canvas, offset, radius * 0.7, paint);
    }
  }

  /// Menggambar satu hexagon
  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) - math.pi / 6;
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

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
