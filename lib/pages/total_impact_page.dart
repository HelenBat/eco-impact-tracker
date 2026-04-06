// lib/pages/total_impact_page.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/usage_service.dart';
import '../widgets/app_drawer.dart';

class TotalImpactPage extends StatefulWidget {
  const TotalImpactPage({Key? key}) : super(key: key);

  @override
  State<TotalImpactPage> createState() => _TotalImpactPageState();
}

class _TotalImpactPageState extends State<TotalImpactPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UsageService _usageService = UsageService();

  // Store absolute sums:
  double _dailyImpact = 0.0;       // Total daily CO₂
  double _monthlyImpact = 0.0;     // Total monthly CO₂
  double _yearlyImpact = 0.0;      // Total yearly CO₂

  double _dailyEnergyImpact = 0.0;     // Total daily battery usage
  double _monthlyEnergyImpact = 0.0;   // Total monthly battery usage
  double _yearlyEnergyImpact = 0.0;    // Total yearly battery usage

  bool _loadingDaily = true;
  bool _loadingMonthly = true;
  bool _loadingYearly = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllData();
  }

  /// Fetch daily, monthly, yearly usage in sequence
  Future<void> _fetchAllData() async {
    await _fetchYearlyImpact();
    await _fetchMonthlyImpact();
    await _fetchDailyImpact();
  }

  /// Yearly = from Jan 1 of this year to now.
  Future<void> _fetchYearlyImpact() async {
    setState(() => _loadingYearly = true);
    try {
      final now = DateTime.now();
      final startThisYear = DateTime(now.year, 1, 1);

      final thisYearData = await _usageService.getRangeUsage(
        start: startThisYear,
        end: now,
      );

      final double thisYearTotalCO2 = thisYearData.fold<double>(
        0, (sum, item) => sum + (item['co2'] as double));
      
      final double thisYearTotalEnergy = thisYearData.fold<double>(
        0, (sum, item) => sum + (item['energy'] as double));

      setState(() {
        _yearlyImpact = thisYearTotalCO2;
        _yearlyEnergyImpact = thisYearTotalEnergy;
      });
    } catch (e) {
      debugPrint('Error fetching yearly usage: $e');
    } finally {
      setState(() => _loadingYearly = false);
    }
  }

  /// Monthly = from the 1st of this month to now.
  Future<void> _fetchMonthlyImpact() async {
    setState(() => _loadingMonthly = true);
    try {
      final now = DateTime.now();
      final startThisMonth = DateTime(now.year, now.month, 1);

      final thisMonthData = await _usageService.getRangeUsage(
        start: startThisMonth,
        end: now,
      );

      final double thisMonthTotalCO2 = thisMonthData.fold<double>(
        0, (sum, item) => sum + (item['co2'] as double));
      
      final double thisMonthTotalEnergy = thisMonthData.fold<double>(
        0, (sum, item) => sum + (item['energy'] as double));

      setState(() {
        _monthlyImpact = thisMonthTotalCO2;
        _monthlyEnergyImpact = thisMonthTotalEnergy;
      });
    } catch (e) {
      debugPrint('Error fetching monthly usage: $e');
    } finally {
      setState(() => _loadingMonthly = false);
    }
  }

  /// Daily = from midnight of today to now.
  Future<void> _fetchDailyImpact() async {
    setState(() => _loadingDaily = true);
    try {
      final now = DateTime.now();
      final startToday = DateTime(now.year, now.month, now.day);

      final todayData = await _usageService.getRangeUsage(
        start: startToday,
        end: now,
      );

      final double todayTotalCO2 = todayData.fold<double>(
        0, (sum, item) => sum + (item['co2'] as double));
      
      final double todayTotalEnergy = todayData.fold<double>(
        0, (sum, item) => sum + (item['energy'] as double));

      setState(() {
        _dailyImpact = todayTotalCO2;
        _dailyEnergyImpact = todayTotalEnergy;
      });
    } catch (e) {
      debugPrint('Error fetching daily usage: $e');
    } finally {
      setState(() => _loadingDaily = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00AB66),
        title: const Text('Total Impact', style: TextStyle(color: Colors.white)),
        actions: [
          // --- RESET BUTTON ---
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
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
                      child: const Text("Reset", style: TextStyle(color: Colors.red)), 
                      onPressed: () => Navigator.pop(ctx, true)
                    ),
                  ],
                ),
              ) ?? false;

              if (!context.mounted) return;

              if (confirm) {
                // 1. Reset Global Data
                await _usageService.resetStatistics();
                
                // 2. Set loading flags to force UI update
                setState(() {
                  _loadingDaily = true;
                  _loadingMonthly = true;
                  _loadingYearly = true;
                });
                
                // 3. Small delay to ensure reset is saved
                await Future.delayed(const Duration(milliseconds: 500));

                // 4. Refresh data (which will now be zero)
                await _fetchAllData(); 

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Data reset successfully!")),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: Container(
        color: Colors.white,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTabContent(_dailyImpact, _dailyEnergyImpact, _loadingDaily),
            _buildTabContent(_monthlyImpact, _monthlyEnergyImpact, _loadingMonthly),
            _buildTabContent(_yearlyImpact, _yearlyEnergyImpact, _loadingYearly),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00AB66),
        onPressed: _fetchAllData,
        tooltip: 'Refresh Data',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  /// Helper to build the chart content
  Widget _buildTabContent(double impact, double energyImpact, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Text(
              "Carbon & Battery Impact",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildBarChart(impact, energyImpact),
            const SizedBox(height: 16),
            Text(
              "CO₂: ${impact.toStringAsFixed(2)} g\nBattery: ${energyImpact.toStringAsFixed(2)} mAh",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  /// Bar chart logic
  Widget _buildBarChart(double co2Value, double batteryValue) {
    double maxY = (co2Value > batteryValue) ? co2Value : batteryValue;
    maxY *= 1.2; 
    if (maxY == 0) maxY = 10; 

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 60,
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final label = value.toInt().toString();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
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
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return const Text('CO₂', style: TextStyle(fontWeight: FontWeight.bold));
                    case 1:
                      return const Text('Battery', style: TextStyle(fontWeight: FontWeight.bold));
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
                BarChartRodData(toY: co2Value, color: Colors.green, width: 30),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(toY: batteryValue, color: Colors.blue, width: 30),
              ],
            ),
          ],
        ),
      ),
    );
  }
}