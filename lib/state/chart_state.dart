import 'package:unfold_dashboard/models/journal_entries.dart';


enum Metric { HRV, RHR, Steps }


enum RangeOption { days7, days30, days90, all }

class DataPoint {
  final DateTime time;
  final double value;

  DataPoint({required this.time, required this.value});
}


class MetricSeries {
  final Metric metric;
  final List<DataPoint> points;
  MetricSeries(this.metric, this.points);
}

class ChartState {
  final Map<Metric, List<DataPoint>> data;
  final List<JournalEntries> journal;
  final bool loading;
  final String? error;
  final RangeOption range;
  final double visibleMinX;
  final double visibleMaxX;
  final double? hoveredX;
  final bool largeDataset;

  ChartState({
    required this.data,
    required this.journal,
    required this.loading,
    required this.error,
    required this.range,
    required this.visibleMinX,
    required this.visibleMaxX,
    this.hoveredX = double.nan,
    this.largeDataset = false,
  });

  ChartState copyWith({
    Map<Metric, List<DataPoint>>? data,
    List<JournalEntries>? journal,
    bool? loading,
    String? error,
    RangeOption? range,
    double? visibleMinX,
    double? visibleMaxX,
    double? hoveredX,
    bool? largeDataset,
  }) {
    return ChartState(
      data: data ?? this.data,
      journal: journal ?? this.journal,
      loading: loading ?? this.loading,
      error: error,
      range: range ?? this.range,
      visibleMinX: visibleMinX ?? this.visibleMinX,
      visibleMaxX: visibleMaxX ?? this.visibleMaxX,
      hoveredX: hoveredX ?? this.hoveredX,
      largeDataset: largeDataset ?? this.largeDataset,
    );
  }
}