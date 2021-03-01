import 'dart:math' as math;

class AxisUtils {
  //计算Y轴相关数据
  static List<int> mathYAxis(num cormax, num cormin, int cornumber) {
    assert(cormax >= cormin);
    assert(cornumber > 0);

    double corstep = (cormax - cormin) / (cornumber);

    if (corstep == 0) {
      return [cormax, 0, 1, cormax];
    }

    int temp;
    if (math.pow(10, math.log(corstep) ~/ math.log(10)) == corstep) {
      temp = math.pow(10, math.log(corstep) ~/ math.log(10));
    } else {
      temp = math.pow(10, math.log(corstep) ~/ math.log(10) + 1);
    }

    double tmpstep = corstep / temp;

    if (tmpstep >= 0 && tmpstep <= 0.1) {
      tmpstep = 0.1;
    } else if (tmpstep >= 0.100001 && tmpstep <= 0.2) {
      tmpstep = 0.2;
    } else if (tmpstep >= 0.200001 && tmpstep <= 0.25) {
      tmpstep = 0.25;
    } else if (tmpstep >= 0.250001 && tmpstep <= 0.5) {
      tmpstep = 0.5;
    } else {
      tmpstep = 1;
    }

    tmpstep = tmpstep * temp;

    if (cormin ~/ tmpstep != cormin / tmpstep) {
      if (cormin < 0) {
        cormin = (-1) * (cormin / tmpstep).abs().ceil() * tmpstep.toInt();
      } else {
        cormin = (cormin ~/ tmpstep).abs() * tmpstep.toInt();
      }
    }
    cormax = (cormax / tmpstep + 1).toInt() * tmpstep.toInt();

    int tmpnumber = (cormax - cormin) ~/ tmpstep;

    if (tmpnumber < cornumber) {
      int extranumber = cornumber - tmpnumber;

      tmpnumber = cornumber;

      if (extranumber % 2 == 0) {
        cormax = (cormax + tmpstep * extranumber / 2).toInt();
      } else {
        cormax = (cormax + tmpstep * (extranumber / 2 + 1)).toInt();
      }

      cormin = (cormin - tmpstep * (extranumber / 2)).toInt();
    }

    cornumber = tmpnumber;

    return [cormax, cormin, cornumber, (cormax - cormin) ~/ cornumber];
  }
}
