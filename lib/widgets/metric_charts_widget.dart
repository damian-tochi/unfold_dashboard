import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/chart_state.dart';
import '../providers/chart_provider.dart';

class MetricChart extends ConsumerWidget {
  final Metric metric;
  final bool showBands;

  const MetricChart({super.key, required this.metric, this.showBands = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chartNotifierProvider);
    final notifier = ref.read(chartNotifierProvider.notifier);
    final data = state.data[metric] ?? [];
    final journal = state.journal;
    final hoveredX = state.hoveredX;

    if (data.isEmpty) {
      return const _EmptyChartView();
    }

    /// Filter out invalid or non-finite values
    final spots = data
        .map((e) => FlSpot(
      e.time.millisecondsSinceEpoch.toDouble(),
      e.value,
    ))
        .where((s) => s.x.isFinite && s.y.isFinite)
        .toList();

    if (spots.isEmpty) {
      return const _EmptyChartView();
    }

    final color = switch (metric) {
      Metric.HRV => Colors.tealAccent,
      Metric.RHR => Colors.redAccent,
      Metric.Steps => Colors.blueAccent,
    };

    final chartTitle = switch (metric) {
      Metric.HRV => "Heart Rate Variability (ms)",
      Metric.RHR => "Resting Heart Rate (bpm)",
      Metric.Steps => "Daily Steps",
    };

    List<HorizontalLine> computeBands(List<FlSpot> spots, Color color) {
      if (spots.length < 7) return [];
      final window = spots.sublist(spots.length - 7);
      final values = window.map((s) => s.y).toList();
      final mean = values.reduce((a, b) => a + b) / values.length;
      final std = sqrt(values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length);
      return [
        HorizontalLine(y: mean + std, color: color.withOpacity(0.25)),
        HorizontalLine(y: mean - std, color: color.withOpacity(0.25)),
      ];
    }

    final List<HorizontalLine> bands = showBands ? computeBands(spots, color) : [];

    final verticals = journal
        .where((j) => j.time != null)
        .map((j) {
      final ts = j.time.millisecondsSinceEpoch.toDouble();
      return VerticalLine(
        x: ts,
        color: Colors.orangeAccent,
        strokeWidth: 1,
        dashArray: [4, 4],
      );
    })
        .toList();

    /// Add shared crosshair only if hoveredX is valid
    if (hoveredX != null && hoveredX.isFinite) {
      verticals.add(
        VerticalLine(
          x: hoveredX,
          color: Colors.blue.withOpacity(0.7),
          strokeWidth: 1.2,
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chartTitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (d) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  final width = box.size.width;
                  if (width <= 0) return;
                  final x = d.localPosition.dx;
                  final minX = spots.first.x;
                  final maxX = spots.last.x;
                  final ratio = (x / width).clamp(0, 1);
                  notifier.setHoveredX(minX + (maxX - minX) * ratio);
                },
                onTapCancel: () => notifier.setHoveredX(null),
                child: InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 0.05,
                  maxScale: 3.0,
                  boundaryMargin: const EdgeInsets.all(10),
                  clipBehavior: Clip.hardEdge,
                  child: LineChart(
                    LineChartData(
                      minX: state.visibleMinX,
                      maxX: state.visibleMaxX,
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: (state.visibleMaxX - state.visibleMinX) / 4,
                            getTitlesWidget: (v, meta) {
                              final dt = DateTime.fromMillisecondsSinceEpoch(v.toInt());
                              return SideTitleWidget(
                                meta: meta,
                                space: 6,
                                child: Text(
                                  '${dt.month}/${dt.day}',
                                  style: const TextStyle(fontSize: 8),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      extraLinesData: ExtraLinesData(
                        horizontalLines: bands,
                        verticalLines: verticals,
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: color,
                          spots: spots,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        handleBuiltInTouches: true,
                        touchCallback: (event, response) {
                          if (event.isInterestedForInteractions && response?.lineBarSpots?.isNotEmpty == true) {
                            notifier.setHoveredX(response!.lineBarSpots!.first.x);
                          }
                        },
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (items) => items
                              .map(
                                (i) => LineTooltipItem(
                              '${DateTime.fromMillisecondsSinceEpoch(i.x.toInt()).toString().split(" ")[0]}\n${i.y.toStringAsFixed(1)}',
                              const TextStyle(color: Colors.white),
                            ),
                          )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nice empty chart view
class _EmptyChartView extends StatelessWidget {
  const _EmptyChartView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "No data available for this range.",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}
