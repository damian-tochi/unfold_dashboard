import 'package:flutter/material.dart';

class ChartControls extends StatelessWidget {
  final String range;
  final ValueChanged<String> onRangeChanged;
  final bool largeDataset;
  final ValueChanged<bool> onToggleLargeDataset;
  final VoidCallback onThemeChange;
  final bool isDarkMode;

  const ChartControls({
    required this.range,
    required this.onRangeChanged,
    required this.largeDataset,
    required this.onToggleLargeDataset,
    required this.onThemeChange,
    required this.isDarkMode,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Switch(value: largeDataset, onChanged: onToggleLargeDataset),
            const SizedBox(width: 8),
            const Text('Toggle Large Dataset'),
            Spacer(),
            IconButton(
              icon: Icon(
                isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              ),
              onPressed: onThemeChange,
            ),
          ],
        ),
        Divider(),
        Row(
          children: [
            _rangeButton(context, '7d'),
            const SizedBox(width: 8),
            _rangeButton(context, '30d'),
            const SizedBox(width: 8),
            _rangeButton(context, '90d'),
            const SizedBox(width: 12),
          ],
        ),
        Divider(),
      ],
    );
  }

  Widget _rangeButton(BuildContext context, String label) {
    final isSelected = label == range;
    return ElevatedButton(
      onPressed: () => onRangeChanged(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }
}
