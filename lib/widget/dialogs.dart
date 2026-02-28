import 'dart:math' as math;
import 'package:flutter/material.dart';

class Dialogs {
  static Future<void> loading(
      BuildContext context, GlobalKey key, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            key: key,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(1, 101, 65, 0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Center(
                      child: _LoadingSpinner(
                        color: const Color.fromRGBO(1, 101, 65, 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromRGBO(1, 101, 65, 1),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> popUp(BuildContext context, String text) async {
    return showDialog<void>(
      context: context, barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Informasi'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(text),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class _LoadingSpinner extends StatefulWidget {
  final Color color;

  const _LoadingSpinner({
    required this.color,
  });

  @override
  State<_LoadingSpinner> createState() => _LoadingSpinnerState();
}

class _LoadingSpinnerState extends State<_LoadingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return CustomPaint(
          size: const Size(50, 50),
          painter: _SpinnerPainter(
            color: widget.color,
            animation: _controller,
          ),
        );
      },
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final Color color;
  final Animation<double> animation;

  _SpinnerPainter({
    required this.color,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * (0.75 - (0.25 * animation.value));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + (2 * math.pi * animation.value),
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) =>
      color != oldDelegate.color || animation != oldDelegate.animation;
}
