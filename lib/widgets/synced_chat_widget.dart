import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journal_entries.dart';
import '../providers/chart_provider.dart';
import '../state/chart_state.dart';
import 'package:intl/intl.dart';

import '../utils/decimation.dart';

class SynchronizedCharts extends ConsumerWidget {
  final StateNotifierProvider<ChartNotifier, ChartState> provider;
  const SynchronizedCharts({required this.provider, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);
    if (state.loading && state.data.values.every((l) => l.isEmpty)) return const Center(child: CircularProgressIndicator());
    if (state.error != null && state.data.values.every((l) => l.isEmpty)) return Center(child: Text('Error: ${state.error}'));
    if (state.data.values.every((l) => l.isEmpty)) return const Center(child: Text('No data available for selected range'));

    return LayoutBuilder(builder: (context, constraints) {
      final chartHeight = (constraints.maxHeight - 16) / 3;
      return Column(children: [
        SizedBox(height: chartHeight, child: _MetricChart(metric: Metric.HRV, title: 'HRV (ms)', provider: provider)),
        const SizedBox(height: 8),
        SizedBox(height: chartHeight, child: _MetricChart(metric: Metric.RHR, title: 'RHR (bpm)', provider: provider)),
        const SizedBox(height: 8),
        SizedBox(height: chartHeight, child: _MetricChart(metric: Metric.Steps, title: 'Steps', provider: provider)),
      ]);
    });
  }
}

class _MetricChart extends ConsumerStatefulWidget {
  final Metric metric;
  final String title;
  final StateNotifierProvider<ChartNotifier, ChartState> provider;
  const _MetricChart({required this.metric, required this.title, required this.provider, super.key});

  @override
  ConsumerState<_MetricChart> createState() => _MetricChartState();
}

class _MetricChartState extends ConsumerState<_MetricChart> {
  Offset? lastPan;
  double lastMinX = double.nan;
  double lastMaxX = double.nan;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);
    final data = state.data[widget.metric] ?? [];
    if (data.isEmpty) return Center(child: Text('No ${widget.title} data'));

    final minX = state.visibleMinX;
    final maxX = state.visibleMaxX;

    final visiblePoints = data.where((p) => p.time.millisecondsSinceEpoch >= minX && p.time.millisecondsSinceEpoch <= maxX).toList();
    final targetPoints = 1200;
    List<DataPoint> renderPoints = visiblePoints;
    if (visiblePoints.length > targetPoints) renderPoints = lttbDownsample(visiblePoints, targetPoints);

    final minY = renderPoints.map((p) => p.value).reduce(min);
    final maxY = renderPoints.map((p) => p.value).reduce(max);
    final spots = renderPoints.map((p) => FlSpot(p.time.millisecondsSinceEpoch.toDouble(), p.value)).toList();

    return GestureDetector(
      onHorizontalDragStart: (d) {
        lastPan = d.localPosition;
        lastMinX = minX;
        lastMaxX = maxX;
      },
      onHorizontalDragUpdate: (d) {
        if (lastPan == null) return;
        final dx = d.localPosition.dx - lastPan!.dx;
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final width = box.size.width;
        final viewSpan = lastMaxX - lastMinX;
        final shift = -dx / width * viewSpan;
        final rangeStart = data.first.time.millisecondsSinceEpoch.toDouble();
        final rangeEnd = data.last.time.millisecondsSinceEpoch.toDouble();
        var newMin = (lastMinX + shift).clamp(rangeStart, rangeEnd - 1);
        var newMax = (lastMaxX + shift).clamp(rangeStart + 1, rangeEnd);
        if (newMax - newMin < 60 * 1000) newMax = newMin + 60 * 1000; // at least 1 minute span
        ref.read(widget.provider.notifier).setViewport(newMin, newMax);
      },
      onScaleStart: (details) {
        lastPan = details.focalPoint;
        lastMinX = minX;
        lastMaxX = maxX;
      },
      onScaleUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final width = box.size.width;
        final viewSpan = lastMaxX - lastMinX;
        final scale = details.scale.clamp(0.5, 4.0);
        final center = details.focalPoint.dx / width;
        final newSpan = (viewSpan / scale).clamp(60 * 1000.0, (data.last.time.millisecondsSinceEpoch - data.first.time.millisecondsSinceEpoch).toDouble());
        final centerTime = lastMinX + viewSpan * center;
        final rangeStart = data.first.time.millisecondsSinceEpoch.toDouble();
        final rangeEnd = data.last.time.millisecondsSinceEpoch.toDouble();
        var newMin = (centerTime - newSpan * center).clamp(rangeStart, rangeEnd - newSpan);
        var newMax = newMin + newSpan;
        ref.read(widget.provider.notifier).setViewport(newMin, newMax);
      },
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final local = details.localPosition;
        final width = box.size.width;
        final t = minX + (local.dx / width) * (maxX - minX);
        ref.read(widget.provider.notifier).setHoveredX(t);
        // check journal entries at tapped time
        final journal = ref.read(widget.provider).journal;
        final nearest = journal.fold<JournalEntries?>(null, (prev, elem) {
          if (prev == null) return elem;
          final dPrev = (prev.time.millisecondsSinceEpoch - t).abs();
          final dElem = (elem.time.millisecondsSinceEpoch - t).abs();
          return dElem < dPrev ? elem : prev;
        });
        if (nearest != null) {
          final dt = DateFormat.yMMMd().add_jm().format(nearest.time);
          showDialog(context: context, builder: (_) => AlertDialog(title: Text(nearest.mood.toString()), content: Text('${nearest.note}$dt'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
      }
      },
      child: Stack(children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: LineChart(LineChartData(
                    minX: minX,
                    maxX: maxX,
                    minY: minY - (maxY - minY) * 0.08,
                    maxY: maxY + (maxY - minY) * 0.08,
                    gridData: FlGridData(show: true, drawVerticalLine: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) {
                        final dt = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                        final fmt = DateFormat('MM/dd HH:mm').format(dt);
                        return Text(fmt, style: const TextStyle(fontSize: 10));
                      }, reservedSize: 40)),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    ),
                    lineBarsData: _buildBars(widget.metric, spots, renderPoints, state),
                    lineTouchData: LineTouchData(enabled: false),
                    extraLinesData: _buildAnnotations(state),
                  )),
                ),
              )
            ]),
          ),
        ),
        // Crosshair & tooltip overlay
        Consumer(builder: (context, ref2, _) {
          final hovered = ref2.watch(widget.provider).hoveredX;
          if (hovered!.isNaN) return const SizedBox.shrink();
          return LayoutBuilder(builder: (context, b) {
            final width = b.maxWidth;
            final xRatio = (hovered - minX) / (maxX - minX);
            final xPos = xRatio.isNaN ? 0.0 : (xRatio * width).clamp(0.0, width);
            DataPoint? near;
            if (renderPoints.isNotEmpty) {
              double bestDist = double.infinity;
              for (final p in renderPoints) {
                final dist = (p.time.millisecondsSinceEpoch.toDouble() - hovered).abs();
                if (dist < bestDist) {
                  bestDist = dist;
                  near = p;
                }
              }
            }
            return Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CrosshairPainter(xPos: xPos),
                  child: near == null
                      ? const SizedBox.shrink()
                      : Stack(children: [
                    Positioned(left: xPos + 8, top: 8, child: Material(elevation: 2, color: Colors.white, child: Padding(padding: const EdgeInsets.all(6.0), child: Text('${near.value.toStringAsFixed(1)}')))),
                  ]),
                ),
              ),
            );
          });
        })
      ]),
    );
  }

  List<LineChartBarData> _buildBars(Metric metric, List<FlSpot> spots, List<DataPoint> renderPoints, ChartState state) {
    final bars = <LineChartBarData>[];
    bars.add(LineChartBarData(spots: spots, isCurved: true, dotData: FlDotData(show: false), belowBarData: BarAreaData(show: false), barWidth: 2));

    // HRV rolling mean + stddev band and mean+10 line
    if (metric == Metric.HRV) {
      final band = _computeRollingMeanStd(renderPoints, Duration(days: 1)); // 1-day rolling window approximates 7-day? We'll compute 7-day below
      // compute 7-day rolling mean & std by window length in points (approx)
      final sevenDayPoints = (Duration(days: 7).inMinutes / 5).round();
      final rolling = _rollingStats(renderPoints.map((e) => e.value).toList(), sevenDayPoints);
      final meanSpots = <FlSpot>[];
      final upperSpots = <FlSpot>[];
      final lowerSpots = <FlSpot>[];
      for (int i = 0; i < renderPoints.length; i++) {
        final dp = renderPoints[i];
        final m = rolling.means[i];
        final s = rolling.stddevs[i];
        if (m.isNaN) continue;
        meanSpots.add(FlSpot(dp.time.millisecondsSinceEpoch.toDouble(), m));
        upperSpots.add(FlSpot(dp.time.millisecondsSinceEpoch.toDouble(), m + s));
        lowerSpots.add(FlSpot(dp.time.millisecondsSinceEpoch.toDouble(), m - s));
      }
      if (meanSpots.isNotEmpty) {
        bars.add(LineChartBarData(spots: meanSpots, isCurved: true, dotData: FlDotData(show: false), barWidth: 1.5, dashArray: [5, 4]));
        // band as filled area between upper and lower handled by an extra LineChartBarData with belowBarData
        bars.add(LineChartBarData(spots: upperSpots, isCurved: true, dotData: FlDotData(show: false), barWidth: 0, belowBarData: BarAreaData(show: true, applyCutOffY: false, cutOffY: 0,)));
      }
      // mean + 10 line
      if (meanSpots.isNotEmpty) {
        final plus10 = meanSpots.map((s) => FlSpot(s.x, s.y + 10)).toList();
        bars.add(LineChartBarData(spots: plus10, isCurved: false, dotData: FlDotData(show: false), barWidth: 1, dashArray: [2, 3]));
      }
    }

    return bars;
  }

  ExtraLinesData _buildAnnotations(ChartState state) {
    final lines = <VerticalLine>[];
    for (final j in state.journal) {
      final x = j.time.millisecondsSinceEpoch.toDouble();
      lines.add(VerticalLine(x: x, color: Colors.orange.withOpacity(0.8), strokeWidth: 1.2, dashArray: [2, 3], label: VerticalLineLabel(show: true, alignment: Alignment.topCenter, labelResolver: (v) => j.mood.toString())));
    }
    return ExtraLinesData(verticalLines: lines);
  }

  // rolling statistics helper
  _RollingStats _rollingStats(List<double> values, int window) {
    final n = values.length;
    final means = List<double>.filled(n, double.nan);
    final stds = List<double>.filled(n, double.nan);
    if (window <= 0) return _RollingStats(means, stds);
    double sum = 0;
    double sumSq = 0;
    int start = 0;
    for (int i = 0; i < n; i++) {
      sum += values[i];
      sumSq += values[i] * values[i];
      while (i - start + 1 > window) {
        sum -= values[start];
        sumSq -= values[start] * values[start];
        start++;
      }
      final len = i - start + 1;
      if (len > 0) {
        final mean = sum / len;
        final variance = (sumSq / len) - (mean * mean);
        final std = variance > 0 ? sqrt(variance) : 0.0;
        means[i] = mean;
        stds[i] = std;
      }
    }
    return _RollingStats(means, stds);
  }

  // placeholder - unused
  _RollingStats _computeRollingMeanStd(List<DataPoint> dp, Duration window) {
    return _rollingStats(dp.map((e) => e.value).toList(), (window.inMinutes / 5).round());
  }
}

class _CrosshairPainter extends CustomPainter {
  final double xPos;
  _CrosshairPainter({required this.xPos});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(xPos, 0), Offset(xPos, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter oldDelegate) => oldDelegate.xPos != xPos;
}

class _RollingStats {
  final List<double> means;
  final List<double> stddevs;
  _RollingStats(this.means, this.stddevs);
}