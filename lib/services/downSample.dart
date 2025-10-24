import 'dart:math';

import 'package:unfold_dashboard/models/time_series_point.dart';

List<BiometricsTimeSeries> downSampleLTTB(List<BiometricsTimeSeries> data, int threshold) {
  if (threshold >= data.length || threshold < 3) return data;
  final sampled = <BiometricsTimeSeries>[];
  final every = (data.length - 2) / (threshold - 2);
  int a = 0;
  sampled.add(data[a]);
  for (int i = 0; i < threshold - 2; i++) {
    final avgRangeStart = (1 + (i * every)).floor();
    final avgRangeEnd = (1 + ((i + 1) * every)).floor();
    final avgRangeEndClamped = avgRangeEnd.clamp(1, data.length - 1);

    double avgX = 0.0, avgY = 0.0;
    final avgRangeLength = (avgRangeEndClamped - avgRangeStart + 1);
    for (int idx = avgRangeStart; idx <= avgRangeEndClamped; idx++) {
      avgX += data[idx].time.millisecondsSinceEpoch.toDouble();
      // avgY += data[idx].value;
      avgY += 0;
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
      // final pointAY = data[a].value;
      final pointAY = 0;
      final pointBX = data[idx].time.millisecondsSinceEpoch.toDouble();
      // final pointBY = data[idx].value;
      final pointBY = 0;

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