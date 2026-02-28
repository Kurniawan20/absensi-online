import 'package:flutter/material.dart';
import 'dart:math' as math;

/// CustomPainter dengan motif lengkungan (Arch) Islami dan lentera gantung
/// Revisi: Revert ke versi simple (tanpa awan/geometris ramai), hanya Arches, Lentera, Bulan, Sparkles.
class IslamicArchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Arches Background (Lengkungan besar di belakang)
    _drawBackgroundArches(canvas, size, paint);

    // Decorative Lines (Garis-garis ornamen)
    _drawDecorativeLines(canvas, size);

    // Hanging Lanterns (Lentera gantung)
    _drawHangingLanterns(canvas, size);

    // Crescent Moon (Bulan Sabit) - Digambar setelah lentera
    _drawCrescentMoon(canvas, size);

    // Sparkles (Kilauan cahaya)
    _drawSparkles(canvas, size);
  }

  void _drawBackgroundArches(Canvas canvas, Size size, Paint paint) {
    // Arch 1: Besar di kanan bawah (Opacity ditingkatkan 0.05 -> 0.10)
    paint.color = Colors.white.withValues(alpha: 0.10);
    final path1 = Path();
    path1.moveTo(0, size.height);
    path1.lineTo(size.width, size.height);
    path1.lineTo(size.width, size.height * 0.4);
    path1.quadraticBezierTo(
      size.width * 0.5, size.height * 0.4, // Control point
      0, size.height * 0.8, // End point
    );
    path1.close();
    canvas.drawPath(path1, paint);

    // Arch 2: Lebih terang, tumpang tindih (Opacity ditingkatkan 0.08 -> 0.15)
    paint.color = Colors.white.withValues(alpha: 0.15);
    final path2 = Path();
    path2.moveTo(size.width * 0.3, size.height);
    path2.lineTo(size.width, size.height);
    path2.lineTo(size.width, size.height * 0.6);
    path2.cubicTo(
      size.width * 0.8,
      size.height * 0.4,
      size.width * 0.5,
      size.height * 0.7,
      size.width * 0.3,
      size.height,
    );
    path2.close();
    canvas.drawPath(path2, paint);

    // Arch 3: Lengkungan mihrab di kiri atas (Opacity ditingkatkan 0.04 -> 0.08)
    paint.color = Colors.white.withValues(alpha: 0.08);
    final path3 = Path();
    path3.moveTo(0, 0);
    path3.lineTo(size.width * 0.4, 0);
    path3.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.3,
      0,
      size.height * 0.5,
    );
    path3.close();
    canvas.drawPath(path3, paint);
  }

  void _drawDecorativeLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2) // Ditingkatkan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0; // Ditingkatkan

    // Garis lengkung dekoratif mengikuti Arch 1
    final path = Path();
    path.moveTo(size.width, size.height * 0.35); // Sedikit di atas arch 1
    path.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.35,
      -20,
      size.height * 0.85,
    );
    canvas.drawPath(path, paint);

    // Garis tambahan untuk aksen
    paint.strokeWidth = 1.0;
    paint.color = Colors.white.withValues(alpha: 0.15);
    final path2 = Path();
    path2.moveTo(size.width, size.height * 0.38);
    path2.quadraticBezierTo(
      size.width * 0.48,
      size.height * 0.38,
      -20,
      size.height * 0.88,
    );
    canvas.drawPath(path2, paint);
  }

  void _drawHangingLanterns(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Lentera 1 (Besar, kanan atas) - Lebih terang
    _drawSingleLantern(canvas, Offset(size.width * 0.85, 0),
        length: size.height * 0.35,
        scale: 1.1,
        opacity: 0.25, // Ditingkatkan
        paint: paint,
        hasGlow: true // Tambah efek cahaya
        );

    // Lentera 2 (Sedang, kiri agak tengah)
    _drawSingleLantern(canvas, Offset(size.width * 0.25, 0),
        length: size.height * 0.22,
        scale: 0.8,
        opacity: 0.20, // Ditingkatkan
        paint: paint,
        hasGlow: true);

    // Lentera 3 (Kecil, kanan jauh)
    _drawSingleLantern(canvas, Offset(size.width * 0.95, 0),
        length: size.height * 0.18,
        scale: 0.6,
        opacity: 0.15, // Ditingkatkan
        paint: paint,
        hasGlow: false);
  }

  void _drawSingleLantern(Canvas canvas, Offset origin,
      {required double length,
      required double scale,
      required double opacity,
      required Paint paint,
      bool hasGlow = false}) {
    // Tali gantungan
    paint.color = Colors.white.withValues(alpha: opacity);
    canvas.drawRect(
        Rect.fromLTWH(origin.dx - 1 * scale, origin.dy, 2 * scale, length),
        paint);

    final center = Offset(origin.dx, origin.dy + length);
    final width = 20.0 * scale;
    final height = 30.0 * scale;

    // Efek Cahaya (Glow) di belakang lentera
    if (hasGlow) {
      final glowPaint = Paint()
        ..color = Colors.yellow.withValues(alpha: 0.15) // Kuning lembut
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

      canvas.drawCircle(
          Offset(center.dx, center.dy + height * 0.6), width * 1.5, glowPaint);
    }

    paint.color =
        Colors.white.withValues(alpha: opacity + 0.1); // Badan lebih terang

    // Atas Lentera (Segitiga/Topi)
    final pathTop = Path();
    pathTop.moveTo(center.dx, center.dy - 5 * scale); // Titik kait
    pathTop.lineTo(center.dx + width * 0.6, center.dy + 5 * scale);
    pathTop.lineTo(center.dx - width * 0.6, center.dy + 5 * scale);
    pathTop.close();
    canvas.drawPath(pathTop, paint);

    // Badan Lentera (Bentuk unik)
    final pathBody = Path();
    pathBody.moveTo(center.dx - width * 0.6, center.dy + 5 * scale);
    pathBody.quadraticBezierTo(center.dx - width, center.dy + height * 0.5,
        center.dx, center.dy + height);
    pathBody.quadraticBezierTo(center.dx + width, center.dy + height * 0.5,
        center.dx + width * 0.6, center.dy + 5 * scale);
    pathBody.close();

    // Isi badan lentera
    canvas.drawPath(pathBody, paint);

    // Detail di tengah lentera (jendela cahaya)
    paint.color =
        Colors.white.withValues(alpha: 0.4); // Lebih terang lagi untuk "kaca"
    final pathWindow = Path();
    pathWindow.moveTo(center.dx - width * 0.3, center.dy + 10 * scale);
    pathWindow.quadraticBezierTo(center.dx - width * 0.5,
        center.dy + height * 0.5, center.dx, center.dy + height * 0.8);
    pathWindow.quadraticBezierTo(
        center.dx + width * 0.5,
        center.dy + height * 0.5,
        center.dx + width * 0.3,
        center.dy + 10 * scale);
    pathWindow.close();
    canvas.drawPath(pathWindow, paint);

    // Bawah Lentera (Ekor kecil)
    paint.color = Colors.white.withValues(alpha: opacity + 0.1);
    canvas.drawCircle(
        Offset(center.dx, center.dy + height + 3 * scale), 3 * scale, paint);
  }

  void _drawCrescentMoon(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          Colors.white.withValues(alpha: 0.25) // Lebih terang (sebelumnya 0.18)
      ..style = PaintingStyle.fill;

    // Posisi bulan di kiri atas
    final center = Offset(size.width * 0.15, size.height * 0.22);
    const radius = 28.0; // Sedikit lebih besar

    final outerPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    // Lingkaran pemotong untuk membuat bentuk sabit
    final innerPath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(center.dx + radius * 0.35, center.dy - radius * 0.15),
        radius: radius * 0.85,
      ));

    // Gabungkan path
    final crescentPath = Path.combine(
      PathOperation.difference,
      outerPath,
      innerPath,
    );

    // Efek glow di belakang bulan
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(crescentPath, glowPaint);

    canvas.drawPath(crescentPath, paint);

    // Tambahkan bintang besar di dekat bulan
    paint.color = Colors.white.withValues(alpha: 0.35); // Bintang utama terang
    _drawStar(canvas,
        Offset(center.dx + radius * 0.9, center.dy - radius * 0.3), 5.0, paint);
  }

  void _drawSparkles(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3); // Lebih terang

    final sparkles = [
      Offset(size.width * 0.8, size.height * 0.5),
      Offset(size.width * 0.2, size.height * 0.35),
      Offset(size.width * 0.6, size.height * 0.22), // Adjusted
      Offset(size.width * 0.1, size.height * 0.6),
      Offset(size.width * 0.45, size.height * 0.15), // New star
      Offset(size.width * 0.9, size.height * 0.7), // New star
    ];

    for (int i = 0; i < sparkles.length; i++) {
      // Variasi ukuran bintang
      double r = (i % 2 == 0) ? 3.5 : 2.5;
      _drawStar(canvas, sparkles[i], r, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      double angle = (i * math.pi / 2) - math.pi / 2;
      // Ujung lancip
      path.moveTo(center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle));
      // Titik dalam (cekungan)
      angle += math.pi / 4;
      path.lineTo(center.dx + (radius * 0.3) * math.cos(angle),
          center.dy + (radius * 0.3) * math.sin(angle));
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
