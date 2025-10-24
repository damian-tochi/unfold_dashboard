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
      return const Center(child: Text("No data"));
    }

    final spots = data
        .map((e) => FlSpot(e.time.millisecondsSinceEpoch.toDouble(), e.value))
        .toList();

    final color = switch (metric) {
      Metric.HRV => Colors.tealAccent,
      Metric.RHR => Colors.redAccent,
      Metric.Steps => Colors.blueAccent,
    };

    String chartTitle = switch (metric) {
      Metric.HRV => "Heart Rate Variability (ms)",
      Metric.RHR => "Resting Heart Rate (bpm)",
      Metric.Steps => "Daily Steps",
    };

    // --- Function to compute bands, this is to avoid recomputation ---
    List<HorizontalLine> _computeBands(List<FlSpot> spots, Color color) {
      if (spots.length < 7) return [];
      final means = <double>[];
      for (int i = 0; i < spots.length; i++) {
        final start = (i - 6).clamp(0, spots.length - 1);
        final window = spots.sublist(start, i + 1).map((s) => s.y).toList();
        final mean = window.reduce((a, b) => a + b) / window.length;
        final std = sqrt(
          window.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
              window.length,
        );
        means.add(mean);
        if (i == spots.length - 1) {
          return [
            HorizontalLine(y: mean + std, color: color.withOpacity(0.25)),
            HorizontalLine(y: mean - std, color: color.withOpacity(0.25)),
          ];
        }
      }
      return [];
    }
    final List<HorizontalLine> bands = showBands ? _computeBands(spots, color) : [];

    // --- Journal markers ---
    final verticals = journal.map((j) {
      final ts = j.time.millisecondsSinceEpoch.toDouble();
      return VerticalLine(
        x: ts,
        color: Colors.orangeAccent,
        strokeWidth: 1,
        dashArray: [4, 4],
        label: VerticalLineLabel(show: false, alignment: Alignment.topRight),
      );
    }).toList();

    // --- Shared Crosshair ---
    verticals.add(
      VerticalLine(
        x: hoveredX!,
        color: Colors.blue.withOpacity(0.7),
        strokeWidth: 1.2,
      ),
    );

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(chartTitle, style: TextStyle(fontSize: 12, fontStyle: FontStyle.normal, fontWeight: FontWeight.w600)),
            SizedBox(height: 5),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (d) {
                  final x = d.localPosition.dx;
                  final width = MediaQuery.of(context).size.width;
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
                  onInteractionEnd: (_) {},
                  child: LineChart(
                    LineChartData(
                      minX: state.visibleMinX,
                      maxX: state.visibleMaxX,
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 5,
                            interval:
                                (state.visibleMaxX - state.visibleMinX) / 4,
                            getTitlesWidget: (v, meta) {
                              final dt = DateTime.fromMillisecondsSinceEpoch(
                                v.toInt(),
                              );
                              final text = Text(
                                '${dt.month}/${dt.day}',
                                style: TextStyle(fontSize: 8),
                              );
                              return SideTitleWidget(
                                space: 6,
                                meta: meta,
                                child: text,
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: null,
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
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
                          if (event.isInterestedForInteractions &&
                              response?.lineBarSpots?.isNotEmpty == true) {
                            final spot = response!.lineBarSpots!.first;
                            notifier.setHoveredX(spot.x);
                          }
                        },
                        touchTooltipData: LineTouchTooltipData(
                          // tooltipBgColor: Colors.black87,
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
