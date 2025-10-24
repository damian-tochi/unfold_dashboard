import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unfold_dashboard/data/data_service.dart';
import 'package:unfold_dashboard/providers/chart_provider.dart';
import 'package:unfold_dashboard/state/chart_state.dart';


/// A minimal chart widget bound to the provider, showing visible range and hovered tooltip
class ChartView extends ConsumerWidget {
  final Metric metric;
  const ChartView(this.metric, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chartNotifierProvider);
    final notifier = ref.read(chartNotifierProvider.notifier);

    return Column(
      key: Key('chart_${metric.name}'),
      children: [
        Text('Range: ${state.range.name}', key: Key('range_${metric.name}')),
        Text('MinX: ${state.visibleMinX}', key: Key('minx_${metric.name}')),
        Text('MaxX: ${state.visibleMaxX}', key: Key('maxx_${metric.name}')),
        if (state.hoveredX != null)
          Text('Tooltip: ${state.hoveredX}', key: Key('tooltip_${metric.name}')),
        ElevatedButton(
          key: Key('range_switch_${metric.name}'),
          onPressed: () async => await notifier.load(RangeOption.days7),
          child: const Text('Switch to 7d'),
        ),
      ],
    );
  }
}

void main() {
  testWidgets('Chart range switch updates all visible X domains and tooltips remain synced', (tester) async {
    final container = ProviderContainer(overrides: [
      chartNotifierProvider.overrideWith((ref) => ChartNotifier(DataService())),
    ]);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ChartView(Metric.HRV),
                ChartView(Metric.RHR),
                ChartView(Metric.Steps),
              ],
            ),
          ),
        ),
      ),
    );

    final notifier = container.read(chartNotifierProvider.notifier);

    // Initial load (e.g. 90 days)
    await notifier.load(RangeOption.days90);
    await tester.pumpAndSettle();

    final initialMinX = container.read(chartNotifierProvider).visibleMinX;
    final initialMaxX = container.read(chartNotifierProvider).visibleMaxX;

    // Simulate hover / tooltip sync
    notifier.setHoveredX(12345);
    await tester.pump();

    expect(find.byKey(const Key('tooltip_HRV')), findsOneWidget);
    expect(find.byKey(const Key('tooltip_RHR')), findsOneWidget);
    expect(find.byKey(const Key('tooltip_Steps')), findsOneWidget);

    // Tap button to switch to 7 days
    await tester.tap(find.byKey(const Key('range_switch_HRV')));
    await tester.pumpAndSettle();

    final newMinX = container.read(chartNotifierProvider).visibleMinX;
    final newMaxX = container.read(chartNotifierProvider).visibleMaxX;

    expect(newMaxX, greaterThan(newMinX));
    expect(newMinX, greaterThan(initialMinX));

    notifier.setHoveredX(99999);
    await tester.pump();

    expect(find.byKey(const Key('tooltip_HRV')), findsOneWidget);
    expect(find.byKey(const Key('tooltip_RHR')), findsOneWidget);
    expect(find.byKey(const Key('tooltip_Steps')), findsOneWidget);
  });
}

