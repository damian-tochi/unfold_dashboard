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

    // 10% random failure
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

/// Example data models
// class BiometricsTimeSeries {
//   final DateTime time;
//   final double hrv;
//   final double hr;
//   final double steps;
//   final double sleepScore;
//
//   BiometricsTimeSeries({
//     required this.time,
//     required this.hrv,
//     required this.hr,
//     required this.steps,
//     required this.sleepScore,
//   });
// }
//
// class JournalEntries {
//   final DateTime time;
//   final int mood;
//   final String note;
//
//   JournalEntries({
//     required this.time,
//     required this.mood,
//     required this.note,
//   });
// }


// class DataService {
//   Future<List<BiometricsTimeSeries>> loadBiometrics() async {
//     try {
//       final jsonString = await rootBundle.loadString('assets/data/biometrics_90d.json');
//       final lines = LineSplitter.split(jsonString).where((l) => l.trim().isNotEmpty);
//       final data = <BiometricsTimeSeries>[];
//
//       for (var line in lines) {
//         final json = jsonDecode(line);
//         final date = DateTime.parse(json['date']);
//         data.add(BiometricsTimeSeries(
//           time: date,
//           hrv: (json['hrv'] as num).toDouble(),
//           hr: (json['hr'] ?? json['rhr'] ?? json['rHr'] ?? 0).toDouble(),
//           steps: (json['steps'] as num).toDouble(),
//           sleepScore: (json['sleepScore'] as num).toDouble(),
//         ));
//       }
//       return data;
//     } catch (e) {
//       throw Exception('Failed to load biometrics: $e');
//     }
//   }
//
//   Future<List<JournalEntries>> loadJournals() async {
//     try {
//       final jsonString = await rootBundle.loadString('assets/data/journals.json');
//       final data = jsonDecode(jsonString) as List;
//       return data.map((e) => JournalEntries(
//         time: DateTime.parse(e['date']),
//         mood: e['mood'],
//         note: e['note'],
//       )).toList();
//     } catch (e) {
//       throw Exception('Failed to load journals: $e');
//     }
//   }
// }
