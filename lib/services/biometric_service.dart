import '../data/data_loader.dart';
import '../models/time_series_point.dart';

class BiometricsService {
  Future<List<BiometricsTimeSeries>> fetchBiometrics() async {
    final data = await DataLoader.loadJsonList('assets/data/biometrics_90d.json');
    return data.map(BiometricsTimeSeries.fromJson).toList();
  }
}
