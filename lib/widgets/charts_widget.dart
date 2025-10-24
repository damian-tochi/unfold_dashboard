import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/journal_entries.dart';
import '../models/time_series_point.dart';
import 'package:flutter/physics.dart';


class ChartPanel extends StatefulWidget {
  final String title;
  final List<BiometricsTimeSeries> data;
  final double Function(BiometricsTimeSeries) field;
  final List<JournalEntries> journals;
  final bool showBands;

  const ChartPanel({
    super.key,
    required this.title,
    required this.data,
    required this.field,
    required this.journals,
    this.showBands = false,
  });

  @override
  State<ChartPanel> createState() => _ChartPanelState();
}

class _ChartPanelState extends State<ChartPanel> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset _velocity = Offset.zero;
  late AnimationController _controller;
  Animation<Offset>? _inertiaAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyMomentum(Offset velocity) {
    _controller.stop();
    _inertiaAnimation = _controller.drive(Tween<Offset>(
      begin: _offset,
      end: _offset + velocity * 0.5,
    ));
    final simulation = FrictionSimulation(0.1, 0, 1);
    _controller.animateWith(simulation);
    _controller.addListener(() {
      setState(() {
        _offset += velocity * 0.016; // time delta ~16ms
        velocity *= 0.92; // damping
        if (velocity.distance < 1) _controller.stop();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.data;
    if (entries.isEmpty) {
      return Text(
        '${widget.title}: No data',
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }

    final minY = entries.map(widget.field).reduce(min);
    final maxY = entries.map(widget.field).reduce(max);
    final color = Theme.of(context).colorScheme.primary;

    double mean = 0, std = 0;
    if (widget.showBands) {
      final values = entries.map(widget.field).toList();
      mean = values.reduce((a, b) => a + b) / values.length;
      std = sqrt(values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length);
    }

    final spots = entries
        .map((e) => FlSpot(e.time.millisecondsSinceEpoch.toDouble(), widget.field(e)))
        .toList();

    final List<HorizontalLine> bands = widget.showBands
        ? [
      HorizontalLine(y: mean + std, color: color.withOpacity(0.3)),
      HorizontalLine(y: mean - std, color: color.withOpacity(0.3)),
    ]
        : [];

    final journalLines = widget.journals.map((j) {
      final ts = j.time.millisecondsSinceEpoch.toDouble();
      return VerticalLine(
        x: ts,
        color: Colors.orangeAccent,
        dashArray: [4, 4],
      );
    }).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              child: InteractiveViewer(
                panEnabled: true,
                scaleEnabled: true,
                minScale: 0.8,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.all(100),
                clipBehavior: Clip.none,
                onInteractionEnd: (_) {}, // optional
                child: Stack(
                  children: [
                    LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(show: true),
                        borderData: FlBorderData(show: false),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: bands,
                          verticalLines: journalLines,
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: color,
                            belowBarData: BarAreaData(show: false),
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                        lineTouchData: LineTouchData(enabled: true),
                        minY: minY - 5,
                        maxY: maxY + 5,
                      ),
                    ),
                    // Overlay invisible tap layer for journals
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (details) {
                          final localX = details.localPosition.dx;
                          final width = context.size!.width;
                          final start = entries.first.time.millisecondsSinceEpoch.toDouble();
                          final end = entries.last.time.millisecondsSinceEpoch.toDouble();
                          final ratio = localX / width;
                          final timestamp = start + (end - start) * ratio;

                          // Find nearest journal
                          final nearest = widget.journals.reduce((a, b) =>
                          (a.time.millisecondsSinceEpoch - timestamp).abs() <
                              (b.time.millisecondsSinceEpoch - timestamp).abs() ? a : b);

                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Journal: ${nearest.mood}/5'),
                              content: Text(nearest.note),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )


          ],
        ),
      ),
    );
  }
}



// class ChartPanel extends StatefulWidget {
//   final String title;
//   final List<BiometricsTimeSeries> data;
//   final double Function(BiometricsTimeSeries) field;
//   final List<JournalEntries> journals;
//   final bool showBands;
//
//   const ChartPanel({
//     super.key,
//     required this.title,
//     required this.data,
//     required this.field,
//     required this.journals,
//     this.showBands = false,
//   });
//
//   @override
//   State<ChartPanel> createState() => _ChartPanelState();
// }
//
// class _ChartPanelState extends State<ChartPanel> {
//   final TransformationController _transformController = TransformationController();
//
//   @override
//   Widget build(BuildContext context) {
//     final entries = widget.data;
//     if (entries.isEmpty) {
//       return Text('${widget.title}: No data', style: Theme.of(context).textTheme.bodyLarge);
//     }
//
//     final color = Theme.of(context).colorScheme.primary;
//     final minY = entries.map(widget.field).reduce(min);
//     final maxY = entries.map(widget.field).reduce(max);
//
//     // HRV mean ± std band
//     double mean = 0, std = 0;
//     if (widget.showBands) {
//       final values = entries.map(widget.field).toList();
//       mean = values.reduce((a, b) => a + b) / values.length;
//       std = sqrt(values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length);
//     }
//
//     final spots = entries
//         .map((e) => FlSpot(e.time.millisecondsSinceEpoch.toDouble(), widget.field(e)))
//         .toList();
//
//     final start = entries.first.time.millisecondsSinceEpoch.toDouble();
//     final end = entries.last.time.millisecondsSinceEpoch.toDouble();
//     final range = end - start;
//
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
//             const SizedBox(height: 8),
//             SizedBox(
//               height: 250,
//               child: LayoutBuilder(
//                 builder: (context, constraints) {
//                   final chartWidth = constraints.maxWidth;
//
//                   return GestureDetector(
//                     behavior: HitTestBehavior.opaque,
//                     onTapUp: (details) {
//                       final localX = details.localPosition.dx;
//                       final scale = _transformController.value.getMaxScaleOnAxis();
//                       final translation = _transformController.value.getTranslation();
//
//                       // Map screen position back to time
//                       final adjustedX = (localX - translation.x) / scale;
//                       final time =
//                           start + (adjustedX / chartWidth) * range;
//
//                       final tapped = widget.journals.firstWhere(
//                             (j) => (j.time.millisecondsSinceEpoch - time).abs() < 12 * 60 * 60 * 1000, // ~12h tolerance
//                         orElse: () => JournalEntries(time: DateTime(0), mood: 0, note: ''),
//                       );
//
//                       if (tapped.time != DateTime(0)) {
//                         showDialog(
//                           context: context,
//                           builder: (_) => AlertDialog(
//                             title: Text('Journal — Mood ${tapped.mood}/5'),
//                             content: Text(tapped.note.isNotEmpty ? tapped.note : 'No notes.'),
//                             actions: [
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context),
//                                 child: const Text('Close'),
//                               ),
//                             ],
//                           ),
//                         );
//                       }
//                     },
//                     child: InteractiveViewer(
//                       transformationController: _transformController,
//                       panEnabled: true,
//                       scaleEnabled: true,
//                       boundaryMargin: const EdgeInsets.all(20),
//                       minScale: 0.8,
//                       maxScale: 3,
//                       clipBehavior: Clip.none,
//                       child: Stack(
//                         children: [
//                           LineChart(
//                             LineChartData(
//                               gridData: FlGridData(show: true, drawVerticalLine: false),
//                               titlesData: FlTitlesData(show: true),
//                               borderData: FlBorderData(show: false),
//                               extraLinesData: ExtraLinesData(
//                                 horizontalLines: widget.showBands
//                                     ? [
//                                   HorizontalLine(y: mean + std, color: color.withOpacity(0.3)),
//                                   HorizontalLine(y: mean - std, color: color.withOpacity(0.3)),
//                                 ]
//                                     : [],
//                               ),
//                               lineBarsData: [
//                                 LineChartBarData(
//                                   spots: spots,
//                                   isCurved: true,
//                                   color: color,
//                                   belowBarData: BarAreaData(show: false),
//                                   dotData: const FlDotData(show: false),
//                                 )
//                               ],
//                               lineTouchData: LineTouchData(
//                                 touchTooltipData: LineTouchTooltipData(
//                                   getTooltipItems: (items) => items
//                                       .map((i) => LineTooltipItem(
//                                     '${DateTime.fromMillisecondsSinceEpoch(i.x.toInt()).toString().split(' ')[0]}\n'
//                                         '${i.y.toStringAsFixed(1)}',
//                                     const TextStyle(color: Colors.white),
//                                   ))
//                                       .toList(),
//                                 ),
//                               ),
//                               minY: minY - 5,
//                               maxY: maxY + 5,
//                             ),
//                           ),
//                           // Marker painter overlays, moves with chart
//                           CustomPaint(
//                             painter: _JournalMarkerPainter(
//                               journals: widget.journals,
//                               start: start,
//                               end: end,
//                               color: Colors.orangeAccent,
//                             ),
//                             size: Size(chartWidth, 250),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _JournalMarkerPainter extends CustomPainter {
//   final List<JournalEntries> journals;
//   final double start;
//   final double end;
//   final Color color;
//
//   _JournalMarkerPainter({
//     required this.journals,
//     required this.start,
//     required this.end,
//     required this.color,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = color.withOpacity(0.9)
//       ..strokeWidth = 2;
//
//     for (final j in journals) {
//       final progress = (j.time.millisecondsSinceEpoch - start) / (end - start);
//       final x = progress * size.width;
//       canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant _JournalMarkerPainter oldDelegate) =>
//       oldDelegate.journals != journals;
// }
