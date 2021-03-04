import 'package:flutter/material.dart';
import 'dart:math' as math;

class HiPieChart extends StatefulWidget {
  final double size;
  final int radius;

  const HiPieChart({
    this.size,
    this.radius = 50,
    Key key,
  }) : super(key: key);

  @override
  _HiPieChartState createState() => _HiPieChartState();
}

class _HiPieChartState extends State<HiPieChart> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, viewport) {
      final size = widget.size ?? math.min(viewport.maxWidth, viewport.maxHeight);

      return Container(
        width: size,
        height: size,
        color: Colors.amberAccent,
        child: CustomPaint(
          painter: _HiPieChartPainter(),
        ),
      );
    });
  }
}

class _HiPieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
