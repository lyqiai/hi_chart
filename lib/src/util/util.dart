import 'package:hi_chart/src/bean/chart_bean.dart';

class Util {
  //对比数据集
  static List<DiffValue> compareDiffData(List<ChartBean> originals, List<ChartBean> data) {
    List<DiffValue> diff = [];

    for (final item in data) {
      final index = data.indexOf(item);

      if (index < originals.length) {
        final original = originals[index];

        if (original.value != item.value) {
          diff.add(DiffValue(index, original.value));
        }
      } else {
        diff.add(DiffValue(index, 0));
      }
    }

    return diff;
  }
}

class DiffValue {
  final int index;
  final num value;

  DiffValue(this.index, this.value);
}
