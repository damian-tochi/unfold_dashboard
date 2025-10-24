import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String? message;
  const EmptyState({this.message, super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(message ?? 'No data available', style: const TextStyle(fontSize: 16))),
    );
  }
}