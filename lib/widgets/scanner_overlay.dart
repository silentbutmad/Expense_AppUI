import 'package:flutter/material.dart';

class ScannerOverlay extends CustomPainter {
  final double cornerSize;
  final double borderSize;
  final Animation<double> scanAnimation;

  ScannerOverlay({
    required this.scanAnimation,
    this.cornerSize = 24,
    this.borderSize = 4,
  }) : super(repaint: scanAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: size.width * 0.8,
        height: size.height * 0.4,
      ),
      const Radius.circular(12),
    );

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(frame)
      ..fillType = PathFillType.evenOdd;
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.6);
    canvas.drawPath(backgroundPath, backgroundPaint);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderSize;

    final path = Path();
    path.moveTo(frame.left, frame.top + cornerSize);
    path.lineTo(frame.left, frame.top);
    path.lineTo(frame.left + cornerSize, frame.top);
    path.moveTo(frame.right - cornerSize, frame.top);
    path.lineTo(frame.right, frame.top);
    path.lineTo(frame.right, frame.top + cornerSize);
    path.moveTo(frame.right, frame.bottom - cornerSize);
    path.lineTo(frame.right, frame.bottom);
    path.lineTo(frame.right - cornerSize, frame.bottom);
    path.moveTo(frame.left + cornerSize, frame.bottom);
    path.lineTo(frame.left, frame.bottom);
    path.lineTo(frame.left, frame.bottom - cornerSize);

    canvas.drawPath(path, paint);

    final scanY = frame.top + frame.height * scanAnimation.value;
    final scanRect = Rect.fromPoints(
      Offset(frame.left + 5, scanY - 3),
      Offset(frame.right - 5, scanY + 3),
    );

    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.cyanAccent.withOpacity(0),
          Colors.cyanAccent,
          Colors.cyanAccent.withOpacity(0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(scanRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    // Use drawRRect to create a scanning line with rounded corners, matching the frame.
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(4)), // Rounded corners for the line
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ScannerOverlay oldDelegate) {
    return oldDelegate.scanAnimation.value != scanAnimation.value ||
           oldDelegate.cornerSize != cornerSize ||
           oldDelegate.borderSize != borderSize;
  }
}
