import 'package:flutter/material.dart';
import 'package:hi_chart/src/bean/chart_bean.dart';
import 'package:hi_chart/src/constant.dart' as constant;
import 'dart:math' as math;

import 'package:hi_chart/src/util/axis_util.dart';

typedef HiCoordinateBuilder = Widget Function(BuildContext context, int cormax, int cormin, double translateX);

class HiCoordinate extends StatefulWidget {
  final HiCoordinateBuilder builder;
  final double width;
  final double height;
  final List<ChartBean> data;
  final Color axisColor;
  final TextStyle labelStyle;
  final double axisWidth;
  final VoidCallback onHorizontalDrag;

  const HiCoordinate({
    @required this.data,
    this.builder,
    this.width,
    this.height,
    this.axisColor = constant.axisColor,
    this.labelStyle,
    this.axisWidth = 1,
    this.onHorizontalDrag,
    Key key,
  }) : super(key: key);

  @override
  _HiCoordinateState createState() => _HiCoordinateState();
}

class _HiCoordinateState extends State<HiCoordinate> {
  num maxValue; //最大值
  num minValue; //最小值
  int cormax, cormin; //优化后最大值、最小值
  int step; //优化后步数大小
  int cornumber; //优化后Y轴分割数

  double translateX = 0; //偏移量
  double maxTranslateX; //最大偏移量
  double startX; //手势临时变量
  double tempTranslateX; //手势临时变量

  @override
  void initState() {
    super.initState();
    initValue();
    initAxisData();
  }

  initValue() {
    minValue = widget.data[0].value;
    maxValue = widget.data[0].value;
    for (final item in widget.data) {
      maxValue = math.max(item.value, maxValue);
      minValue = math.min(item.value, minValue);
    }
  }

  initAxisData() {
    final yAxisData = AxisUtils.mathYAxis(maxValue, minValue, constant.cornumber);
    cormax = yAxisData[0];
    cormin = yAxisData[1];
    cornumber = yAxisData[2];
    step = yAxisData[3];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(
              painter: _HiCoordinatePainter(
                data: widget.data,
                cornumber: cornumber,
                step: step,
                axisColor: widget.axisColor,
                axisWidth: widget.axisWidth,
                labelStyle: widget.labelStyle,
                translateX: translateX,
              ),
            ),
          ),
          if (widget.builder != null)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, viewport) {
                  final out = (widget.data.length + 1) * constant.pointSpace - viewport.maxWidth;
                  maxTranslateX = math.max(0, out);

                  return GestureDetector(
                    onHorizontalDragStart: _onHorizontalDragStart,
                    onHorizontalDragUpdate: _onHorizontalDragUpdate,
                    onHorizontalDragEnd: _onHorizontalDragEnd,
                    child: widget.builder(context, cormax, cormin, translateX),
                  );
                },
              ),
              bottom: constant.xLabelHeight,
            ),
        ],
      ),
    );
  }

  /*
    更新偏移量
   */
  void _onHorizontalDragStart(DragStartDetails details) {
    startX = details.globalPosition.dx;
    tempTranslateX = translateX;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final distanceX = details.globalPosition.dx - startX;
    final tempX = tempTranslateX + distanceX;
    if (tempX > 0 || tempX.abs() > maxTranslateX) return;

    setState(() {
      translateX = tempX;
    });

    if (widget.onHorizontalDrag != null) widget.onHorizontalDrag();
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    startX = null;
    tempTranslateX = null;
  }

/*
    更新偏移量
   */
}

class _HiCoordinatePainter extends CustomPainter {
  final List<ChartBean> data;
  final int cornumber;
  final Color axisColor;
  final double axisWidth;
  final TextStyle labelStyle;
  final double translateX;
  final int step;

  Paint axisPaint; //坐标轴画笔

  _HiCoordinatePainter({
    @required this.data,
    @required this.cornumber,
    @required this.step,
    this.axisColor,
    this.axisWidth,
    this.labelStyle,
    this.translateX = 0,
  }) {
    init();
  }

  void init() {
    axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = axisWidth
      ..style = PaintingStyle.stroke;
  }

  @override
  void paint(Canvas canvas, Size size) {
    //调整画布为正常笛卡尔坐标系
    canvas.save();
    canvas.scale(1, -1);
    canvas.translate(0, -size.height + constant.xLabelHeight);

    drawAxis(canvas, size);
    drawAxisLabel(canvas, size);

    canvas.restore();
  }

  //绘制坐标轴
  void drawAxis(Canvas canvas, Size size) {
    //绘制X轴
    final xAxisPath = Path();
    xAxisPath.lineTo(size.width, 0);

    canvas.drawPath(xAxisPath, axisPaint);

    //绘制Y轴
    final yAxisPath = Path();
    yAxisPath.lineTo(0, size.height);

    canvas.drawPath(yAxisPath, axisPaint);
  }

  //绘制坐标轴标签
  void drawAxisLabel(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(1, -1);
    canvas.clipRect(Rect.fromLTWH(constant.pointSpace / 2, -constant.xLabelHeight, size.width - constant.pointSpace / 2, size.height));

    final labelTextStyle = labelStyle ?? TextStyle(fontSize: 14, color: axisColor);

    for (final item in data) {
      final index = data.indexOf(item) + 1;
      final offset = Offset(index * constant.pointSpace + translateX, 2);

      TextPainter(
        text: TextSpan(
          text: item.title,
          style: labelTextStyle,
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )
        ..layout(minWidth: constant.pointSpace, maxWidth: constant.pointSpace)
        ..paint(canvas, offset);
    }
    canvas.restore();

    canvas.save();
    canvas.scale(1, -1);

    final ySpace = size.height / cornumber;

    for (int i = 0; i <= cornumber; i++) {
      final labelNumber = i * step;
      final offset = Offset(5, -ySpace * i);

      TextPainter(
        text: TextSpan(text: '$labelNumber', style: labelTextStyle),
        textDirection: TextDirection.ltr,
      )
        ..layout(minWidth: constant.yLabelWidth, maxWidth: constant.yLabelWidth)
        ..paint(canvas, offset);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
