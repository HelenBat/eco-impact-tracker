// lib/pages/analysis_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/usage_service.dart';
import '../widgets/app_drawer.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({Key? key}) : super(key: key);

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>
    with SingleTickerProviderStateMixin {
  // Singleton UsageService
  final UsageService _usageService = UsageService();

  // Loading state + today's usage data
  bool _isLoading = false;
  List<Map<String, dynamic>> _todayUsageData = [];

  // List of supported apps
  final List<String> _supportedApps = [
    'com.google.android.youtube',
    'tv.twitch.android.app',
    'com.twitter.android',
    'com.linkedin.android',
    'com.facebook.katana',
    'com.snapchat.android',
    'com.instagram.android',
    'com.pinterest',
    'com.reddit.frontpage',
    'com.zhiliaoapp.musically',
  ];

  // Friendly names for the apps
  final Map<String, String> _appFriendlyNames = {
    'com.google.android.youtube': 'YouTube',
    'tv.twitch.android.app': 'Twitch',
    'com.twitter.android': 'Twitter',
    'com.linkedin.android': 'LinkedIn',
    'com.facebook.katana': 'Facebook',
    'com.snapchat.android': 'Snapchat',
    'com.instagram.android': 'Instagram',
    'com.pinterest': 'Pinterest',
    'com.reddit.frontpage': 'Reddit',
    'com.zhiliaoapp.musically': 'TikTok',
  };

  // Custom color palette for each app
  final Map<String, Color> _appColors = {
    'com.google.android.youtube': const Color(0xFFFF0000),
    'tv.twitch.android.app': const Color(0xFFF3722C),
    'com.twitter.android': const Color(0xFF1DA1F2),
    'com.linkedin.android': const Color(0xFF0077B5),
    'com.facebook.katana': const Color(0xFF1877F2),
    'com.snapchat.android': const Color(0xFFFFFC00),
    'com.instagram.android': const Color(0xFFE4405F),
    'com.pinterest': const Color(0xFF4D908E),
    'com.reddit.frontpage': const Color(0xFF577590),
    'com.zhiliaoapp.musically': const Color(0xFF277DA1),
  };

  @override
  void initState() {
    super.initState();
    _fetchTodayUsageData();
  }

  /// Fetch today's usage data and store it in _todayUsageData
  Future<void> _fetchTodayUsageData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await _usageService.getTodayUsage();
      if (!mounted) return;
      setState(() {
        _todayUsageData = data;
      });
    } catch (e) {
      debugPrint('Error fetching usage data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Build a pie chart for CO₂ usage
  Widget _buildCO2PieChart() {
    // Aggregate CO₂ by app package
    final Map<String, double> co2Map = {};
    for (var entry in _todayUsageData) {
      final pkg = entry['package'];
      final co2 = entry['co2'] as double?;
      if (co2 != null) {
        co2Map[pkg] = (co2Map[pkg] ?? 0) + co2;
      }
    }

    // Ensure every supported app is included (even if 0)
    for (var pkg in _supportedApps) {
      co2Map[pkg] ??= 0;
    }

    // Calculate total CO₂
    final double totalCO2 = co2Map.values.fold(0.0, (sum, val) => sum + val);
    if (totalCO2 == 0) {
      return const Center(child: Text("No CO₂ data available for today."));
    }

    // Build slices for the pie chart (only for apps with > 0 usage).
    final sections = <PieChartSectionData>[];
    co2Map.forEach((pkg, co2Val) {
      if (co2Val > 0) {
        final double percentage = (co2Val / totalCO2) * 100;
        sections.add(
          PieChartSectionData(
            color: _appColors[pkg] ?? Colors.grey,
            value: co2Val,
            title: "${percentage.toStringAsFixed(1)}%", // e.g. "12.3%"
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    });

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend for CO₂
        Column(
          children: co2Map.entries
              .where((e) => e.value > 0)
              .map((e) {
            final pkg = e.key;
            final co2Val = e.value;
            final color = _appColors[pkg] ?? Colors.grey;
            final friendlyName = _appFriendlyNames[pkg] ?? pkg;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 16, height: 16, color: color),
                  const SizedBox(width: 8),
                  Text(
                    "$friendlyName: ${co2Val.toStringAsFixed(1)} g CO₂",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          })
              .toList(),
        ),
      ],
    );
  }

  /// Build a pie chart for Battery (energy) usage
  Widget _buildBatteryPieChart() {
    // Aggregate battery usage (energy) by app package
    final Map<String, double> batteryMap = {};
    for (var entry in _todayUsageData) {
      final pkg = entry['package'];
      final energy = entry['energy'] as double?;
      if (energy != null) {
        batteryMap[pkg] = (batteryMap[pkg] ?? 0) + energy;
      }
    }

    // Ensure every supported app is included (even if 0)
    for (var pkg in _supportedApps) {
      batteryMap[pkg] ??= 0;
    }

    // Calculate total battery usage
    final double totalBattery = batteryMap.values.fold(0.0, (sum, val) => sum + val);
    if (totalBattery == 0) {
      return const Center(child: Text("No battery usage data available for today."));
    }

    // Build slices for the pie chart (only for apps with > 0 usage).
    final sections = <PieChartSectionData>[];
    batteryMap.forEach((pkg, batteryVal) {
      if (batteryVal > 0) {
        final double percentage = (batteryVal / totalBattery) * 100;
        sections.add(
          PieChartSectionData(
            color: _appColors[pkg] ?? Colors.grey,
            value: batteryVal,
            title: "${percentage.toStringAsFixed(1)}%",
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    });

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend for battery usage
        Column(
          children: batteryMap.entries
              .where((e) => e.value > 0)
              .map((e) {
            final pkg = e.key;
            final batteryVal = e.value;
            final color = _appColors[pkg] ?? Colors.grey;
            final friendlyName = _appFriendlyNames[pkg] ?? pkg;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 16, height: 16, color: color),
                  const SizedBox(width: 8),
                  Text(
                    "$friendlyName: ${batteryVal.toStringAsFixed(1)} mAh",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          })
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // We have two tabs: CO2 and Battery
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Usage Analysis'),
          actions: [
            // --- RESET BUTTON ADDED HERE ---
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              tooltip: "Reset All Data",
              onPressed: () async {
                bool confirm = await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Reset Statistics?"),
                        content:
                            const Text("This will reset all charts to zero."),
                        actions: [
                          TextButton(
                              child: const Text("Cancel"),
                              onPressed: () => Navigator.pop(ctx, false)),
                          TextButton(
                              child: const Text("Reset",
                                  style: TextStyle(color: Colors.red)),
                              onPressed: () => Navigator.pop(ctx, true)),
                        ],
                      ),
                    ) ??
                    false;

                  if (!context.mounted) return;

                if (confirm) {
                  // 1. Reset Global Data
                  await _usageService.resetStatistics();

                  // 2. Refresh THIS page's specific data
                  await _fetchTodayUsageData();

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Data reset successfully!")),
                  );
                }
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            tabs: [
              Tab(text: "CO₂ Analysis"),
              Tab(text: "Battery Analysis"),
            ],
          ),
        ),
        drawer: const AppDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchTodayUsageData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 600, // Enough space for both tabs
                    child: TabBarView(
                      children: [
                        // Tab 1: CO2 Pie Chart
                        _buildCO2PieChart(),
                        // Tab 2: Battery Pie Chart
                        _buildBatteryPieChart(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}