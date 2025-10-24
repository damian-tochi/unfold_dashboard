import 'package:flutter_test/flutter_test.dart';
import 'package:unfold_dashboard/data/data_service.dart';
import 'package:unfold_dashboard/providers/chart_provider.dart';
import 'package:unfold_dashboard/state/chart_state.dart';



void main() {
  group('ChartNotifier Tests', () {
    test('Downsampling reduces dataset to requested size', () {
      final notifier = ChartNotifier(DataService());
      final now = DateTime.now();

      final data = List.generate(
        1000,
            (i) => DataPoint(time: now.add(Duration(seconds: i)), value: i.toDouble()),
      );

      final result = notifier.debugDownsample(data, 100);

      expect(result.length, lessThanOrEqualTo(100));
      expect(result.first.value, isA<double>());
      expect(result.last.value, isA<double>());

      // Check that values are roughly in same range
      final originalMin = data.first.value;
      final originalMax = data.last.value;
      expect(result.first.value, greaterThanOrEqualTo(originalMin));
      expect(result.last.value, lessThanOrEqualTo(originalMax));
    });

    test('Loading with different ranges updates visibleMinX and visibleMaxX', () async {
      final notifier = ChartNotifier(DataService());

      await notifier.load(RangeOption.days7);
      final range7Min = notifier.state.visibleMinX;
      final range7Max = notifier.state.visibleMaxX;
      expect(range7Max - range7Min, greaterThan(0));

      await notifier.load(RangeOption.days30);
      final range30Min = notifier.state.visibleMinX;
      expect(range30Min, lessThan(range7Min)); // wider range
    });

    test('Toggle large dataset forces reload with simulated data', () async {
      final notifier = ChartNotifier(DataService());
      notifier.toggleLargeDataset(true);
      expect(notifier.state.largeDataset, isTrue);
      expect(notifier.state.data.isNotEmpty, isTrue);
    });
  });
}
