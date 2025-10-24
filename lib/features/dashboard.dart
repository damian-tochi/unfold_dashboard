import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unfold_dashboard/models/journal_entries.dart';
import '../models/time_series_point.dart';
import '../providers/chart_provider.dart';
import '../services/biometric_service.dart';
import '../services/downSample.dart';
import '../services/journal_service.dart';
import '../state/chart_state.dart';
import '../widgets/chart_controls.dart';
import '../widgets/charts_widget.dart';
import '../widgets/loading_state.dart';
import '../widgets/error_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/metric_charts_widget.dart';
import '../widgets/synced_chat_widget.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final biometricsService = BiometricsService();
  final journalService = JournalService();

  List<BiometricsTimeSeries> _biometrics = [];
  List<JournalEntries> _journals = [];

  bool _loading = true;
  bool _error = false;
  bool _largeDataset = false;
  String _range = '7d';

  late Future<SharedPreferences> _prefsFuture;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadData();
  }

  Future<void> _loadData() async {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(chartNotifierProvider.notifier).load(RangeOption.days30),
    );
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final bio = await biometricsService.fetchBiometrics();
      final jrn = await journalService.fetchJournals();

      setState(() {
        _biometrics = bio;
        _journals = jrn;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  List<BiometricsTimeSeries> _filteredData() {
    final now = DateTime.now();
    final duration = _range == '7d'
        ? Duration(days: 7)
        : _range == '30d'
        ? Duration(days: 30)
        : Duration(days: 90);

    final start = now.subtract(duration);
    final filtered = _biometrics.where((e) => e.time.isAfter(start)).toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    // Simulate large dataset
    final expanded = _largeDataset
        ? List.generate(10000, (i) {
            final base = filtered.isEmpty
                ? DateTime.now()
                : filtered.first.time;
            return BiometricsTimeSeries(
              time: base.add(Duration(minutes: i * 5)),
              hrv: 50 + Random().nextDouble() * 10,
              hr: 55 + Random().nextInt(15).toDouble(),
              steps: 5000 + Random().nextInt(8000).toDouble(),
              sleepScore: 70 + Random().nextInt(10).toDouble(),
            );
          })
        : filtered;

    // Downsample for large range
    if (_range != '7d' || _largeDataset) {
      return downSampleLTTB(expanded, 500);
    }
    return expanded;
  }

  Future<void> _loadTheme() async {
    final prefs = await _prefsFuture;
    setState(() => _isDarkMode = prefs.getBool('admin_dark') ?? false);
  }

  Future<void> _saveTheme(bool v) async {
    final prefs = await _prefsFuture;
    await prefs.setBool('admin_dark', v);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingState();
    if (_error) return ErrorState(onRetry: _loadData);
    if (_biometrics.isEmpty) return const EmptyState();
    final state = ref.watch(chartNotifierProvider);
    final filtered = _filteredData();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F9FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        cardColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF151617),
          elevation: 0,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        cardColor: const Color(0xFF151617),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ChartControls(
                //   range: _range,
                //   onRangeChanged: (r) => setState(() => _range = r),
                //   largeDataset: _largeDataset,
                //   onToggleLargeDataset: (v) =>
                //       setState(() => _largeDataset = v),
                //   onThemeChange: () {
                //     setState(() => _isDarkMode = !_isDarkMode);
                //     _saveTheme(_isDarkMode);
                //   },
                //   isDarkMode: _isDarkMode,
                // ),
                ChartControls(
                  range: state.range.name,
                  onRangeChanged: (r) {
                    final opt = switch (r) {
                      '7d' => RangeOption.days7,
                      '30d' => RangeOption.days30,
                      '90d' => RangeOption.days90,
                      _ => RangeOption.days30,
                    };
                    ref.read(chartNotifierProvider.notifier).load(opt);
                  },
                  largeDataset: state.largeDataset,
                  onToggleLargeDataset: (v) =>
                      ref.read(chartNotifierProvider.notifier).toggleLargeDataset(v),
                  onThemeChange: () {
                    setState(() => _isDarkMode = !_isDarkMode);
                    _saveTheme(_isDarkMode);
                  },
                  isDarkMode: _isDarkMode,
                ),

                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // ChartPanel(
                        //   title: "Heart Rate Variability (ms)",
                        //   data: filtered,
                        //   field: (e) => e.hrv,
                        //   journals: _journals,
                        //   showBands: true,
                        // ),
                        // const SizedBox(height: 16),
                        // ChartPanel(
                        //   title: "Resting Heart Rate (bpm)",
                        //   data: filtered,
                        //   field: (e) => e.hr.toDouble(),
                        //   journals: _journals,
                        // ),
                        // const SizedBox(height: 16),
                        // ChartPanel(
                        //   title: "Steps",
                        //   data: filtered,
                        //   field: (e) => e.steps.toDouble(),
                        //   journals: _journals,
                        // ),
                        SizedBox(
                          height: 300,
                          child: MetricChart(
                            metric: Metric.HRV,
                            showBands: true,
                          ),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          height: 300,
                          child: MetricChart(metric: Metric.RHR),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          height: 300,
                          child: MetricChart(metric: Metric.Steps),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
