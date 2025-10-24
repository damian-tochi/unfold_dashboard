import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/chart_provider.dart';
import '../state/chart_state.dart';
import '../widgets/chart_controls.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/error_state.dart';
import '../widgets/metric_charts_widget.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  late Future<SharedPreferences> _prefsFuture;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _prefsFuture = SharedPreferences.getInstance();
    _loadTheme();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chartNotifierProvider.notifier).load(RangeOption.days30);
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await _prefsFuture;
    if (mounted) {
      setState(() => _isDarkMode = prefs.getBool('admin_dark') ?? false);
    }
  }

  Future<void> _saveTheme(bool value) async {
    final prefs = await _prefsFuture;
    await prefs.setBool('admin_dark', value);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chartNotifierProvider);

    if (state.loading) return const LoadingState();
    if (state.error != null) {
      return ErrorState(
        message: state.error!,
        onRetry: () => ref
            .read(chartNotifierProvider.notifier)
            .load(state.range, force: true),
      );
    }
    final noData = state.data.values.every((list) => list.isEmpty);
    if (noData) {
      return EmptyState(
        message: 'No biometric data available for this range.',
        onRetry: () => ref
            .read(chartNotifierProvider.notifier)
            .load(state.range, force: true),
      );
    }

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
          child: _buildDashboard(context, state),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, ChartState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                children: const [
                  SizedBox(height: 300, child: MetricChart(metric: Metric.HRV, showBands: true)),
                  SizedBox(height: 12),
                  SizedBox(height: 300, child: MetricChart(metric: Metric.RHR)),
                  SizedBox(height: 12),
                  SizedBox(height: 300, child: MetricChart(metric: Metric.Steps)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
