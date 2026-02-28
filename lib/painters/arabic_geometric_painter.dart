import 'package:flutter/material.dart';
import 'dart:math' as math;

/// CustomPainter bertema Arabesque — pola geometris islami dengan
/// interlocking stars dan tessellation
class ArabicGeometricPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Pola bintang 8 sudut berulang (tessellation)
    _drawStarTessellation(canvas, size, paint);

    // Pola lingkaran saling terhubung
    _drawInterlockingCircles(canvas, size, paint);

    // Bulan sabit dekoratif
    _drawDecorativeCrescent(canvas, size);
  }

  /// Menggambar tessellation bintang 8 sudut
  void _drawStarTessellation(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.white.withValues(alpha: 0.12);
    const spacing = 50.0;
    final cols = (size.width / spacing).ceil() + 1;
    final rows = (size.height / spacing).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        // Offset setiap baris genap agar membentuk pola brick
        final offsetX = (row % 2 == 0) ? 0.0 : spacing * 0.5;
        final center = Offset(
          col * spacing + offsetX,
          row * spacing,
        );

        // Hitung jarak dari tengah untuk variasi opacity
        final distFromCenter =
            (center - Offset(size.width * 0.5, size.height * 0.5)).distance;
        final maxDist = size.width * 0.7;
        final opacity = 0.12 * (1 - (distFromCenter / maxDist).clamp(0.0, 0.8));

        if (opacity > 0.02) {
          paint.color = Colors.white.withValues(alpha: opacity);
          _drawEightPointStar(canvas, center, spacing * 0.28, paint);
        }
      }
    }
  }

  /// Menggambar satu bintang 8 sudut
  void _drawEightPointStar(
      Canvas canvas, Offset center, double radius, Paint paint) {
    // Bintang dibuat dari 2 kotak yang dirotasi 45 derajat
    final path1 = _createRotatedSquare(center, radius, 0);
    final path2 = _createRotatedSquare(center, radius * 0.85, math.pi / 4);

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);

    // Titik pusat kecil
    canvas.drawCircle(center, 1.5, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
  }

  /// Membuat kotak yang dirotasi
  Path _createRotatedSquare(Offset center, double radius, double rotation) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = rotation + (i * math.pi / 2) + math.pi / 4;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  /// Menggambar lingkaran saling terhubung (motif islami klasik)
  void _drawInterlockingCircles(Canvas canvas, Size size, Paint paint) {
    paint
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.8;

    const radius = 30.0;
    final positions = [
      Offset(size.width * 0.05, size.height * 0.15),
      Offset(size.width * 0.95, size.height * 0.25),
      Offset(size.width * 0.08, size.height * 0.85),
      Offset(size.width * 0.92, size.height * 0.80),
    ];

    for (final pos in positions) {
      // Lingkaran utama
      canvas.drawCircle(pos, radius, paint);

      // 6 lingkaran kecil di sekelilingnya
      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        final smallCenter = Offset(
          pos.dx + radius * math.cos(angle),
          pos.dy + radius * math.sin(angle),
        );
        canvas.drawCircle(smallCenter, radius * 0.5, paint);
      }
    }
  }

  /// Menggambar bulan sabit dekoratif dengan ornamen
  void _drawDecorativeCrescent(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width * 0.82, size.height * 0.12);
    const radius = 18.0;

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

    // Bintang kecil di samping bulan
    paint.color = Colors.white.withValues(alpha: 0.18);
    _drawSmallStar(canvas,
        Offset(center.dx + radius * 1.2, center.dy - radius * 0.3), 4.0, paint);
  }

  /// Menggambar bintang kecil dekoratif
  void _drawSmallStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - math.pi / 2;
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

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
