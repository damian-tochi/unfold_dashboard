import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;
  const ErrorState({required this.onRetry, this.message, super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text(message ?? 'Failed to load data', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry'))
        ]),
      ),
    );
  }
}