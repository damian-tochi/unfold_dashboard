import '../models/journal_entries.dart';
import '../models/time_series_point.dart';
import 'dart:async';
import 'dart:math';
import 'data_loader.dart';


class DataService {
  final _rng = Random();

  /// Simulate network delay and 10% random failure
  Future<void> _simulateLatency() async {
    final delay = 700 + _rng.nextInt(500);
    await Future.delayed(Duration(milliseconds: delay));

    /// 10% random failure
    if (_rng.nextDouble() < 0.1) {
      throw Exception("Network error: failed to fetch data");
    }
  }

  Future<List<BiometricsTimeSeries>> loadBiometrics() async {
    await _simulateLatency();
    try {
      final data = await DataLoader.loadJsonList('assets/data/biometrics_90d.json');
      return data.map(BiometricsTimeSeries.fromJson).toList();
    } catch (e) {
      throw Exception('Failed to load biometrics: $e');
    }
  }

  Future<List<JournalEntries>> loadJournals() async {
    await _simulateLatency();
    try {
      final data = await DataLoader.loadJsonList('assets/data/journals.json');
      return data.map(JournalEntries.fromJson).toList();
    } catch (e) {
      throw Exception('Failed to load journals: $e');
    }
  }
}
