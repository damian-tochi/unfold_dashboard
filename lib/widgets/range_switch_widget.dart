import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chart_provider.dart';
import '../state/chart_state.dart';


class RangeSwitcher extends ConsumerWidget {
  final StateNotifierProvider<ChartNotifier, ChartState> provider;
  const RangeSwitcher({required this.provider, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);
    return Row(children: [
      _rangeButton(ref, '7d', RangeOption.days7, state.range),
      const SizedBox(width: 8),
      _rangeButton(ref, '30d', RangeOption.days30, state.range),
      const SizedBox(width: 8),
      _rangeButton(ref, '90d', RangeOption.days90, state.range),
      const SizedBox(width: 8),
      ElevatedButton(onPressed: () => ref.read(provider.notifier).load(RangeOption.all), child: const Text('All')),
      const Spacer(),
      if (state.loading) ...[
        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 8),
        const Text('Loading...'),
      ],
      if (state.error != null) ...[
        const SizedBox(width: 16),
        ElevatedButton.icon(onPressed: () => ref.read(provider.notifier).load(state.range, force: true), icon: const Icon(Icons.refresh), label: const Text('Retry'))
      ]
    ]);
  }


  Widget _rangeButton(WidgetRef ref, String label, RangeOption opt, RangeOption selected) {
    final isSelected = opt == selected;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: isSelected ? Colors.blue : Colors.grey[300], foregroundColor: isSelected ? Colors.white : Colors.black),
      onPressed: () => ref.read(provider.notifier).load(opt),
      child: Text(label),
    );
  }
}