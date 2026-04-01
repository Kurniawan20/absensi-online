import 'package:flutter/material.dart';

class GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Create overlapping rectangles
    var path1 = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.7, 0)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(0, size.height)
      ..close();

    var path2 = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.8, size.height)
      ..lineTo(size.width * 0.3, size.height)
      ..close();

    // Draw the paths with different opacities
    canvas.drawPath(path1, paint..color = Colors.black.withValues(alpha: 0.05));
    canvas.drawPath(path2, paint..color = Colors.black.withValues(alpha: 0.07));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
