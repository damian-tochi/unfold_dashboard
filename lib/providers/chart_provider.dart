import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/data_service.dart';
import '../models/time_series_point.dart';
import '../state/chart_state.dart';

final _svcProvider = Provider((ref) => DataService());
final chartNotifierProvider = StateNotifierProvider<ChartNotifier, ChartState>((ref) {
  return ChartNotifier(ref.read(_svcProvider));
});


class ChartNotifier extends StateNotifier<ChartState> {
  final DataService _svc;
  ChartNotifier(this._svc)
      : super(ChartState(
    data: {Metric.HRV: [], Metric.RHR: [], Metric.Steps: []},
    journal: [],
    loading: false,
    error: null,
    range: RangeOption.days30,
    visibleMinX: DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch.toDouble(),
    visibleMaxX: DateTime.now().millisecondsSinceEpoch.toDouble(),
  ));


  Future<void> load(RangeOption range, {bool force = false}) async {
    state = state.copyWith(loading: true, error: null, range: range);

    try {
      ///Load both biometrics & journals
      List<BiometricsTimeSeries> biometrics;
      if (state.largeDataset) {
        ///Simulate large data
        final now = DateTime.now();
        biometrics = List.generate(10000, (i) {
          final t = now.subtract(Duration(minutes: 5 * (10000 - i)));
          return BiometricsTimeSeries(
            time: t,
            hrv: 50 + Random().nextDouble() * 10,
            hr: 55 + Random().nextInt(15).toDouble(),
            steps: 5000 + Random().nextInt(8000).toDouble(),
            sleepScore: 70 + Random().nextInt(10).toDouble(),
          );
        });
      } else {
        biometrics = await _svc.loadBiometrics();
      }
      final journals = await _svc.loadJournals();

      /// Transform biometrics into DataPoints per metric
      final hrvPoints = biometrics
          .map((b) => DataPoint(time: b.time, value: b.hrv))
          .toList();
      final rhrPoints = biometrics
          .map((b) => DataPoint(time: b.time, value: b.hr))
          .toList();
      final stepsPoints = biometrics
          .map((b) => DataPoint(time: b.time, value: b.steps))
          .toList();

      ///Build map by metric type
      final map = <Metric, List<DataPoint>>{
        Metric.HRV: hrvPoints,
        Metric.RHR: rhrPoints,
        Metric.Steps: stepsPoints,
      };

      ///Compute visible X range for charts
      final now = DateTime.now();
      final start = now.subtract(Duration(
        days: switch (range) {
          RangeOption.days7 => 7,
          RangeOption.days30 => 30,
          RangeOption.days90 => 90,
          RangeOption.all => biometrics.length,
        },

      ));

      ///Apply downsampling for performance on larger ranges
      if (!force) {
        if (range == RangeOption.days30) {
          map.updateAll((key, list) => _downsample(list, 1000));
        } else if (range == RangeOption.days90) {
          map.updateAll((key, list) => _downsample(list, 2000));
        }
      }

      state = state.copyWith(
        data: map,
        journal: journals,
        loading: false,
        error: null,
        visibleMinX: start.millisecondsSinceEpoch.toDouble(),
        visibleMaxX: now.millisecondsSinceEpoch.toDouble(),
      );
    } catch (e, st) {
      debugPrint('Error loading data: $e\n$st');
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  List<DataPoint> _downsample(List<DataPoint> data, int target) {
    if (data.length <= target) return data;

    final ratio = (data.length / target).floor();
    final reduced = <DataPoint>[];
    for (var i = 0; i < data.length; i += ratio) {
      final slice = data.sublist(i, (i + ratio).clamp(0, data.length));
      final avg = slice.map((e) => e.value).reduce((a, b) => a + b) / slice.length;
      reduced.add(DataPoint(time: slice.first.time, value: avg));
    }
    return reduced;
  }

  void setViewport(double minX, double maxX) {
    state = state.copyWith(visibleMinX: minX, visibleMaxX: maxX);
  }

  void toggleLargeDataset(bool enabled) {
    state = state.copyWith(largeDataset: enabled);
    load(state.range, force: true);
  }

  void setHoveredX(double? x) {
    state = state.copyWith(hoveredX: x);
  }


  @visibleForTesting
  List<DataPoint> debugDownsample(List<DataPoint> data, int target) => _downsample(data, target);


}