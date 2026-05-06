import 'dart:math';
import 'package:flutter/material.dart';

class MiniSparkline extends StatelessWidget {
  final List<double> values;
  final Color color;

  const MiniSparkline({super.key, required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (values.isEmpty) {
          return const SizedBox(); // Return an empty box if there are no values
        }
        final double maxVal = values.reduce(max);
        final double minVal = values.reduce(min);
        final double range = (maxVal - minVal == 0) ? 1.0 : maxVal - minVal;
        return CustomPaint(
          painter: _SparklinePainter(values, minVal, range, color),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final double minVal, range;
  final Color color;

  _SparklinePainter(this.values, this.minVal, this.range, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (values.length < 2) return;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - minVal) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => 
    oldDelegate.values != values || oldDelegate.color != color;
}
