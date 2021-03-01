import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hi_chart/src/bean/chart_bean.dart';
import 'package:hi_chart/src/util/axis_util.dart';
import 'package:hi_chart/src/util/path_util.dart';
import 'package:hi_chart/src/util/util.dart';

//X轴间隔
final double _pointSpace = 40;
//X轴底部标签高度
final double _xLabelHeight = 40;
//默认Y轴分割数
final int _cornumber = 5;

class LineChart extends StatefulWidget {
  final List<ChartBean> data; //数据集
  final double width; //宽度
  final double height; //高度
  final Color lineColor; //线、点颜色
  final Color axisColor; //坐标轴颜色
  final TextStyle axisTextStyle; //坐标轴标签字体样式
  final double lineWidth; //线宽度

  const LineChart({
    @required this.data,
    this.width = double.infinity,
    this.height,
    this.axisColor = const Color(0xffe6e6e6),
    this.lineColor,
    this.axisTextStyle,
    this.lineWidth = 1,
    Key key,
  }) : super(key: key);

  @override
  _LineChartState createState() => _LineChartState();
}

class _LineChartState extends State<LineChart> with TickerProviderStateMixin {
  double translateX = 0; //偏移量
  double maxTranslateX; //最大偏移量

  double width; //宽度
  double height; //高度

  List<Offset> points = []; //点集合

  double startX; //手势临时变量
  double tempTranslateX; //手势临时变量

  String tipTitle; //提示标题
  String tipValue; //提示数据值
  double tipTop; //提示顶部距离
  double tipLeft; //提示底部距离
  bool isShowTip = false; //是否显示提示
  Timer tipTimer; //自动关闭提示
  GlobalKey tipKey = GlobalKey(); //提示key

  num maxValue; //最大值
  num minValue; //最小值
  int cormax, cormin; //优化后最大值、最小值
  int step; //优化后步数大小
  int cornumber; //优化后Y轴分割数

  AnimationController initAnimationController; //初始化动画

  AnimationController changeAnimationController; //数据变更动画

  List<DiffValue> changeList; //数据变更数据集

  @override
  void initState() {
    super.initState();

    initValue();

    initAxisData();

    initAnimationController = AnimationController(duration: Duration(seconds: 1), vsync: this)
      ..addListener(() {
        setState(() {});
      });

    changeAnimationController = AnimationController(duration: Duration(milliseconds: 300), vsync: this)
      ..addListener(() {
        setState(() {});
      });

    initAnimationController.forward();
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
    final yAxisData = AxisUtils.mathYAxis(maxValue, minValue, _cornumber);
    cormax = yAxisData[0];
    cormin = yAxisData[1];
    cornumber = yAxisData[2];
    step = yAxisData[3];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onTapUp: _onTapUp,
      child: Container(
        width: widget.width,
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, viewport) {
            final out = (widget.data.length + 1) * _pointSpace - viewport.maxWidth;
            maxTranslateX = math.max(0, out);
            width = viewport.maxWidth;
            height = viewport.maxHeight;

            return Stack(
              children: [
                CustomPaint(
                  willChange: true,
                  size: viewport.biggest,
                  painter: _LineChartPaint(
                    context: context,
                    data: widget.data,
                    axisColor: widget.axisColor,
                    translateX: translateX,
                    cormax: cormax,
                    cormin: cormin,
                    cornumber: cornumber,
                    step: step,
                    maxValue: maxValue,
                    minValue: minValue,
                    lineColor: widget.lineColor,
                    lineWidth: widget.lineWidth,
                    axisTextStyle: widget.axisTextStyle,
                    onPointsChanged: (points) {
                      this.points = points;
                    },
                    progress: initAnimationController.value,
                    changeList: changeList,
                    changeProgress: changeAnimationController.value,
                  ),
                ),
                Positioned(
                  top: isShowTip ? tipTop : -99999,
                  left: tipLeft,
                  child: Container(
                    key: tipKey,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    constraints: BoxConstraints(minWidth: 60),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tipTitle ?? '',
                          style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          tipValue ?? '',
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
    hideTip();

    final distanceX = details.globalPosition.dx - startX;
    final tempX = tempTranslateX + distanceX;
    if (tempX > 0 || tempX.abs() > maxTranslateX) return;

    setState(() {
      translateX = tempX;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    startX = null;
    tempTranslateX = null;
  }

  /*
    更新偏移量
   */

  void _onTapUp(TapUpDetails details) {
    final localPosition = details.localPosition;
    final transerPosition = Offset(localPosition.dx, height - _xLabelHeight - localPosition.dy);

    //是否点击到了点
    final finder = points?.firstWhere((point) => Rect.fromCenter(center: transerPosition, width: 8, height: 8).contains(point), orElse: () => null);

    if (finder != null) {
      final index = points.indexOf(finder);
      tipTitle = widget.data[index].title;
      tipValue = widget.data[index].value.toString();

      setState(() {
        isShowTip = true;
        autoCloseTip();
      });

      tipTop = localPosition.dy;

      if (localPosition.dx + tipKey.currentContext.size.width > width) {
        tipLeft = localPosition.dx - (localPosition.dx + tipKey.currentContext.size.width - width);
      } else {
        tipLeft = localPosition.dx;
      }

      setState(() {});
    } else {
      hideTip();
    }
  }

  //关闭提示计时器
  void cancelTipTimer() {
    if (tipTimer != null && tipTimer.isActive) {
      tipTimer.cancel();
    }
  }

  //自动延迟关闭提示
  void autoCloseTip() {
    cancelTipTimer();

    tipTimer = Timer(Duration(seconds: 3), hideTip);
  }

  //关闭提示
  void hideTip() {
    if (isShowTip) {
      setState(() {
        isShowTip = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant LineChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    //更新数据集
    if (oldWidget.data != widget.data) {
      initValue();
      initAxisData();

      changeList = Util.compareDiffData(oldWidget.data, widget.data);
      changeAnimationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    initAnimationController.dispose();

    changeAnimationController.dispose();

    cancelTipTimer();
    super.dispose();
  }
}

class _LineChartPaint extends CustomPainter {
  final List<ChartBean> data;
  final BuildContext context;
  final Color axisColor;
  final TextStyle axisTextStyle;

  final Color lineColor;
  final lineWidth;

  final ValueChanged<List<Offset>> onPointsChanged;
  final double translateX;

  final num maxValue;
  final num minValue;
  final int cormax, cormin;
  final int step;
  final int cornumber;

  final double progress; //初始化动画进度
  final double changeProgress; //数据集变更动画进度
  final List<DiffValue> changeList;

  Paint _axisPaint; //坐标轴画笔
  Paint _pointPaint; //点画笔
  Paint _linePaint; //线画笔

  _LineChartPaint({
    @required this.context,
    @required this.data,
    this.translateX = 0,
    this.axisColor,
    this.axisTextStyle,
    this.lineWidth,
    this.lineColor,
    this.onPointsChanged,
    this.maxValue,
    this.minValue,
    this.cormin,
    this.cormax,
    this.cornumber,
    this.step,
    this.progress,
    this.changeList,
    this.changeProgress,
  }) {
    init();
  }

  init() {
    _axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    _pointPaint = Paint()
      ..color = lineColor ?? Theme.of(context).primaryColor
      ..strokeWidth = lineWidth + 4
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    _linePaint = Paint()
      ..color = lineColor ?? Theme.of(context).primaryColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    final coordinateSize = Size(size.width, size.height - _xLabelHeight);

    //调整画布为正常笛卡尔坐标系
    canvas.scale(1, -1);
    canvas.translate(0, -size.height + _xLabelHeight);

    _drawAxis(canvas, coordinateSize);
    _drawAxisLabel(canvas, coordinateSize);
    _drawPoint(canvas, coordinateSize);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  //绘制坐标轴
  void _drawAxis(Canvas canvas, Size size) {
    //绘制X轴
    final xAxisPath = Path();
    xAxisPath.lineTo(size.width, 0);

    canvas.drawPath(xAxisPath, _axisPaint);

    //绘制Y轴
    final yAxisPath = Path();
    yAxisPath.lineTo(0, size.height);

    canvas.drawPath(yAxisPath, _axisPaint);
  }

  //绘制坐标轴标签
  void _drawAxisLabel(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(1, -1);
    canvas.clipRect(Rect.fromLTWH(_pointSpace / 2, -_xLabelHeight, size.width - _pointSpace / 2, size.height));

    final labelTextStyle = axisTextStyle ?? TextStyle(fontSize: 14, color: axisColor);

    for (final item in data) {
      final index = data.indexOf(item) + 1;
      final offset = Offset(index * _pointSpace + translateX, 2);

      TextPainter(
        text: TextSpan(
          text: item.title,
          style: labelTextStyle,
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )
        ..layout(minWidth: _pointSpace, maxWidth: _pointSpace)
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
        ..layout(minWidth: 50, maxWidth: 50)
        ..paint(canvas, offset);
    }

    canvas.restore();
  }

  //绘制点和线
  void _drawPoint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(_pointSpace / 2, 0, size.width - _pointSpace / 2, size.height));

    List<Offset> points = [];
    Path path = Path();

    for (final item in data) {
      final index = data.indexOf(item);
      final value = item.value;
      double y = size.height * (value / (cormax - cormin)) - _pointPaint.strokeWidth / 2;
      final x = (index + 1) * _pointSpace + (_pointSpace - _pointPaint.strokeWidth) / 2;

      final finder = changeList?.firstWhere((item) => item.index == index, orElse: () => null);
      if (finder != null) {
        double oldY = size.height * (finder.value / (cormax - cormin)) - _pointPaint.strokeWidth / 2;
        y = oldY + (y - oldY) * changeProgress;
      }

      final point = Offset(x + translateX, y);

      points.add(point);

      if (index == 0) {
        path.moveTo(x + translateX, y);
      } else {
        path.lineTo(x + translateX, y);
      }
    }

    if (onPointsChanged != null) {
      onPointsChanged(points);
    }

    canvas.drawPoints(PointMode.points, points, _pointPaint);

    canvas.drawPath(PathUtil.createAnimatedPath(path, progress), _linePaint);

    canvas.restore();
  }
}
