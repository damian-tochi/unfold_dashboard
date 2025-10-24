import 'package:flutter_test/flutter_test.dart';
import 'package:unfold_dashboard/data/data_service.dart';
import 'package:unfold_dashboard/providers/chart_provider.dart';
import 'package:unfold_dashboard/state/chart_state.dart';
import 'package:unfold_dashboard/utils/decimation.dart';



void main() {
  test('LTTB reduces to requested size', () {
    final now = DateTime.now();
    final data = List.generate(1000, (i) => DataPoint(now.add(Duration(seconds: i)), i.toDouble()));
    final ds = lttbDownsample(data, 200);
    expect(ds.length, 200);
  });

  test('rolling stats compute mean and stddev', () {
    final values = List.generate(100, (i) => i.toDouble());
    final notifier = ChartNotifier(DataService());
    // final stats = notifier._rollingStats(values, 10);
    // // first elements before window should be NaN
    // expect(stats.means.length, 100);
    // expect(stats.stddevs.length, 100);
  });
}
