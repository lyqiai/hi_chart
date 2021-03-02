import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hi_chart/src/bean/chart_bean.dart';
import 'package:hi_chart/src/constant.dart' as constant;
import 'package:hi_chart/src/util/path_util.dart';
import 'package:hi_chart/src/util/util.dart';
import 'package:hi_chart/src/widget/coordinate.dart';

class HiLineChart extends StatefulWidget {
  final List<ChartBean> data; //数据集
  final double width; //宽度
  final double height; //高度
  final Color lineColor; //线、点颜色
  final Color axisColor; //坐标轴颜色
  final TextStyle axisLabelStyle; //坐标轴标签字体样式
  final double axisWidth; // 坐标轴宽度
  final double lineWidth; //线宽度

  const HiLineChart({
    @required this.data,
    this.width = double.infinity,
    this.height,
    this.axisColor = const Color(0xffe6e6e6),
    this.lineColor,
    this.axisLabelStyle,
    this.axisWidth = 1,
    this.lineWidth = 1,
    Key key,
  }) : super(key: key);

  @override
  _LineChartState createState() => _LineChartState();
}

class _LineChartState extends State<HiLineChart> with TickerProviderStateMixin {
  List<Offset> points = []; //点集合

  String tipTitle; //提示标题
  String tipValue; //提示数据值
  double tipTop; //提示顶部距离
  double tipLeft; //提示底部距离
  bool isShowTip = false; //是否显示提示
  Timer tipTimer; //自动关闭提示
  GlobalKey tipKey = GlobalKey(); //提示key

  GlobalKey contentKey = GlobalKey(); //内容区域

  AnimationController initAnimationController; //初始化动画

  AnimationController changeAnimationController; //数据变更动画

  List<DiffValue> changeList; //数据变更数据集

  @override
  void initState() {
    super.initState();

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

  @override
  Widget build(BuildContext context) {
    return HiCoordinate(
      data: widget.data,
      width: widget.width,
      height: widget.height,
      axisColor: widget.axisColor,
      axisWidth: widget.axisWidth,
      labelStyle: widget.axisLabelStyle,
      onHorizontalDrag: () {
        hideTip();
      },
      builder: (context, cormax, cormin, translateX) => GestureDetector(
        onTapUp: _onTapUp,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                key: contentKey,
                willChange: true,
                painter: _LineChartPaint(
                  context: context,
                  data: widget.data,
                  translateX: translateX,
                  cormax: cormax,
                  cormin: cormin,
                  lineColor: widget.lineColor,
                  lineWidth: widget.lineWidth,
                  onPointsChanged: (points) {
                    this.points = points;
                  },
                  progress: initAnimationController.value,
                  changeList: changeList,
                  changeProgress: changeAnimationController.value,
                ),
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
        ),
      ),
    );
  }

  void _onTapUp(TapUpDetails details) {
    final width = contentKey.currentContext.size.width;
    final height = contentKey.currentContext.size.height;

    final localPosition = details.localPosition;
    final transerPosition = Offset(localPosition.dx, height - localPosition.dy);

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
  void didUpdateWidget(covariant HiLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    //更新数据集
    if (oldWidget.data != widget.data) {
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

  final Color lineColor;
  final lineWidth;

  final ValueChanged<List<Offset>> onPointsChanged;
  final double translateX;

  final int cormax, cormin;

  final double progress; //初始化动画进度
  final double changeProgress; //数据集变更动画进度
  final List<DiffValue> changeList;

  Paint _pointPaint; //点画笔
  Paint _linePaint; //线画笔

  _LineChartPaint({
    @required this.context,
    @required this.data,
    this.translateX = 0,
    this.onPointsChanged,
    this.lineWidth,
    this.lineColor,
    this.cormin,
    this.cormax,
    this.progress,
    this.changeList,
    this.changeProgress,
  }) {
    init();
  }

  init() {
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
    //调整画布为正常笛卡尔坐标系
    canvas.scale(1, -1);
    canvas.translate(0, -size.height);

    _drawPoint(canvas, size);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  //绘制点和线
  void _drawPoint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(constant.pointSpace / 2, 0, size.width - constant.pointSpace / 2, size.height));

    List<Offset> points = [];
    Path path = Path();

    for (final item in data) {
      final index = data.indexOf(item);
      final value = item.value;
      double y = size.height * (value / (cormax - cormin)) - _pointPaint.strokeWidth / 2;
      final x = (index + 1) * constant.pointSpace + (constant.pointSpace - _pointPaint.strokeWidth) / 2;

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
