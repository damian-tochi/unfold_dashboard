class BiometricsTimeSeries {
  final DateTime time;
  final double hrv;
  final double hr;
  final double steps;
  final double sleepScore;

  BiometricsTimeSeries({
    required this.time,
    required this.hrv,
    required this.hr,
    required this.steps,
    required this.sleepScore,
  });

  factory BiometricsTimeSeries.fromJson(Map<String, dynamic> json) {
    return BiometricsTimeSeries(
      time: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      hrv: (json['hrv'] ?? 0).toDouble(),
      hr: (json['hr'] ?? json['heartRate'] ?? 0).toInt(),
      steps: (json['steps'] ?? 0).toInt(),
      sleepScore: (json['sleepScore'] ?? 0).toInt(),
    );
  }
}
