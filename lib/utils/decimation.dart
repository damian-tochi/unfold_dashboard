import 'dart:math';

import '../state/chart_state.dart';

List<DataPoint> lttbDownsample(List<DataPoint> data, int threshold) {
  if (threshold >= data.length || threshold == 0) return data;
  final sampled = <DataPoint>[];
  final every = (data.length - 2) / (threshold - 2);
  int a = 0;
  sampled.add(data[a]);
  for (int i = 0; i < threshold - 2; i++) {
    final avgRangeStart = (1 + (i * every)).floor();
    final avgRangeEnd = (1 + ((i + 1) * every)).floor();
    final avgRangeEndClamped = avgRangeEnd.clamp(1, data.length - 1);

    double avgX = 0.0;
    double avgY = 0.0;
    final avgRangeLength = (avgRangeEndClamped - avgRangeStart + 1);
    for (int idx = avgRangeStart; idx <= avgRangeEndClamped; idx++) {
      avgX += data[idx].time.millisecondsSinceEpoch.toDouble();
      avgY += data[idx].value;
    }
    avgX /= max(1, avgRangeLength);
    avgY /= max(1, avgRangeLength);

    final rangeOffs = (((i) * every) + 1).floor();
    final rangeTo = (((i + 1) * every) + 1).floor();
    final rangeToClamped = min(rangeTo, data.length - 1);

    double maxArea = -1.0;
    int maxAreaIdx = rangeOffs;
    for (int idx = rangeOffs; idx <= rangeToClamped; idx++) {
      final pointAX = data[a].time.millisecondsSinceEpoch.toDouble();
      final pointAY = data[a].value;
      final pointBX = data[idx].time.millisecondsSinceEpoch.toDouble();
      final pointBY = data[idx].value;

      final area = ((pointAX - avgX) * (pointBY - pointAY) - (pointAX - pointBX) * (avgY - pointAY)).abs() * 0.5;
      if (area > maxArea) {
        maxArea = area;
        maxAreaIdx = idx;
      }
    }

    sampled.add(data[maxAreaIdx]);
    a = maxAreaIdx;
  }
  sampled.add(data.last);
  return sampled;
}
