import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EmptyState extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  const EmptyState({required this.onRetry, this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
            Lottie.asset(
              'assets/lottie/Empty_state_ghost.json',
              height: 120,
              width: 120,
              animate: true,
            ),
          const SizedBox(height: 12),
            Text(
              message ?? 'No data available',
              style: const TextStyle(fontSize: 16),
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry'))
          ],
        ),
      ),
    );
  }
}
