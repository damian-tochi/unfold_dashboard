import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class DataLoader {
  static final _random = Random();

  static Future<List<Map<String, dynamic>>> loadJsonList(String path) async {
    // Simulate 700–1200 ms latency
    await Future.delayed(Duration(milliseconds: 700 + _random.nextInt(500)));

    // Random 10% failure
    if (_random.nextDouble() < 0.1) {
      throw Exception('Network error: failed to fetch $path');
    }

    try {
      final raw = await rootBundle.loadString(path);
      final decoded = json.decode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>() // Skip invalid entries
            .toList();
      }
      return [];
    } catch (e) {
      // Gracefully handle corrupt/missing JSON
      print('⚠️ Error loading $path: $e');
      return [];
    }
  }
}
