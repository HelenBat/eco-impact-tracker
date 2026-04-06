// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/usage_service.dart';
import '../widgets/app_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  // Use the Singleton instance
  final UsageService _usageService = UsageService();
  
  String? _selectedApp;
  Map<String, dynamic>? _selectedAppData;
  bool _isLoading = false;

  // List of supported app package names.
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

  // Mapping of package names to friendly names.
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Observe app lifecycle
    _selectedApp = _supportedApps.first;
    _fetchUsageForSelectedApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Refreshes data when user comes back from Settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _fetchUsageForSelectedApp();
    }
  }

  // Fetch usage data using the Singleton service
  Future<void> _fetchUsageForSelectedApp() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final usageList = await _usageService.getTodayUsage();
      
      // Filter records for the selected app.
      final filtered = usageList.where((entry) => entry['package'] == _selectedApp).toList();
      
      double totalCO2 = 0.0;
      double totalEnergy = 0.0;
      double totalMinutes = 0.0;
      
      for (var entry in filtered) {
        totalCO2 += (entry['co2'] as double);
        totalEnergy += (entry['energy'] as double);
        totalMinutes += (entry['minutes'] as double);
      }

      if (!mounted) return;
      
      setState(() {
        _selectedAppData = {
          'co2': totalCO2,
          'energy': totalEnergy,
          'minutes': totalMinutes,
        };
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error fetching usage: $e");
    }
  }

  // Build the chart widget
  Widget _buildChart() {
    if (_selectedAppData == null) {
      return const Center(child: Text('No data available'));
    }

    double co2 = _selectedAppData!['co2'] as double;
    double energy = _selectedAppData!['energy'] as double;

    double maxY = (co2 > energy) ? co2 : energy;
    if (maxY == 0) maxY = 10; 
    maxY *= 1.2; 

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      switch (value.toInt()) {
                        case 0:
                          return const Text('CO₂');
                        case 1:
                          return const Text('Energy');
                        default:
                          return const Text('');
                      }
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: co2,
                      color: const Color(0xFF00AB66),
                      width: 30,
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: energy,
                      color: const Color(0xFFFF8609),
                      width: 30,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'CO₂: ${co2.toStringAsFixed(1)} g',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Energy: ${energy.toStringAsFixed(1)} mAh',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Impact'),
        actions: [
          // TRASH (RESET) BUTTON
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Color.fromARGB(255, 255, 255, 255)),
            tooltip: "Reset All Data",
            onPressed: () async {
              bool confirm = await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Reset Statistics?"),
                  content: const Text("This will reset all charts to zero."),
                  actions: [
                    TextButton(
                      child: const Text("Cancel"), 
                      onPressed: () => Navigator.pop(ctx, false)
                    ),
                    TextButton(
                      child: const Text("Reset", style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))), 
                      onPressed: () => Navigator.pop(ctx, true)
                    ),
                  ],
                ),
              ) ?? false;

              if (!context.mounted) return;

              if (confirm) {
                setState(() => _isLoading = true);
                
                await UsageService().resetStatistics();
                await Future.delayed(const Duration(milliseconds: 500));
                await _fetchUsageForSelectedApp();

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Data reset successfully!")),
                );
              }
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Welcome to Eco-Impact Tracker!",
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Discover how your favorite apps impact the environment.",
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Select the app to see its impact:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select an App',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedApp,
                    items: _supportedApps.map((app) {
                      return DropdownMenuItem(
                        value: app,
                        child: Text(_appFriendlyNames[app] ?? app),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedApp = value;
                      });
                      _fetchUsageForSelectedApp();
                    },
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildChart(),
                  ),
                  // --- ADD THIS DISCLAIMER HERE ---
                  const Padding(
                    padding: EdgeInsets.only(top: 30, bottom: 80, left: 16, right: 16),
                    child: Text(
                      "Note: Data may take 5–10 minutes to update on devices with strict battery optimization (e.g., OnePlus, Xiaomi). \n\nTip: Force-close the target app (e.g. YouTube) to speed up detection.",
                      style: TextStyle(
                        color: Colors.grey, 
                        fontSize: 12, 
                        fontStyle: FontStyle.italic
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          setState(() => _isLoading = true);
          await _fetchUsageForSelectedApp();
          setState(() => _isLoading = false);
        },
        tooltip: 'Refresh Data',
        backgroundColor: Colors.lightGreen,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}