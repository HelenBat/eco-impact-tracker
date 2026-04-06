// lib/pages/stats_page.dart

import 'package:flutter/material.dart';
import '../services/usage_service.dart';
import '../widgets/charts.dart';
import '../widgets/app_drawer.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  // Use the Singleton UsageService
  final UsageService _usageService = UsageService();

  final Map<String, List<Map<String, dynamic>>> _usageDataByPeriod = {
    'weekly': [],
    'monthly': [],
    'yearly': [],
  };

  bool _loadingWeekly = true;
  bool _loadingMonthly = true;
  bool _loadingYearly = true;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    await _fetchWeeklyUsage();
    await _fetchMonthlyUsage();
    await _fetchYearlyUsage();
  }

  Future<void> _fetchWeeklyUsage() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));
      final usageList = await _usageService.getRangeUsage(start: start, end: now);
      if (!mounted) return;
      setState(() {
        _usageDataByPeriod['weekly'] = usageList;
      });
    } catch (e) {
      debugPrint('Error fetching weekly usage: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingWeekly = false;
        });
      }
    }
  }

  Future<void> _fetchMonthlyUsage() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month - 1, now.day);
      final usageList = await _usageService.getRangeUsage(start: start, end: now);
      if (!mounted) return;
      setState(() {
        _usageDataByPeriod['monthly'] = usageList;
      });
    } catch (e) {
      debugPrint('Error fetching monthly usage: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingMonthly = false;
        });
      }
    }
  }

  Future<void> _fetchYearlyUsage() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year - 1, now.month, now.day);
      final usageList = await _usageService.getRangeUsage(start: start, end: now);
      if (!mounted) return;
      setState(() {
        _usageDataByPeriod['yearly'] = usageList;
      });
    } catch (e) {
      debugPrint('Error fetching yearly usage: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingYearly = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage Statistics'),
        actions: [
          // RESET BUTTON
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
                
                // 2. Set Loading State
                setState(() {
                  _loadingWeekly = true;
                  _loadingMonthly = true;
                  _loadingYearly = true;
                });
                
                // 3. Small delay
                await Future.delayed(const Duration(milliseconds: 500));
                
                // 4. Refresh Data
                await _fetchAllData(); 

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
      body: _loadingWeekly || _loadingMonthly || _loadingYearly
          ? const Center(child: CircularProgressIndicator())
          : SocialMediaPieChart(
              usageDataByPeriod: _usageDataByPeriod,
            ),
    );
  }
}