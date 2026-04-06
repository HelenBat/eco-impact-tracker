import 'package:flutter/material.dart';

import '../services/usage_service.dart';
import '../widgets/app_drawer.dart';

class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({Key? key}) : super(key: key);

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  final UsageService _usageService = UsageService();

  bool _loading = true;
  bool _hasPermission = false;
  DateTime? _lastCheckAt;
  DateTime? _lastSuccessfulFetch;
  int _trackedAppsFound = 0;
  int _totalTrackedMinutes = 0;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);

    try {
      final hasPermission = await _usageService.hasUsagePermission();
      final data = await _usageService.getRangeUsage(start: start, end: now);

      final totalMinutes = data.fold<double>(
        0,
        (sum, row) => sum + ((row['minutes'] as num?)?.toDouble() ?? 0),
      );

      if (!mounted) return;
      setState(() {
        _hasPermission = hasPermission;
        _lastCheckAt = now;
        _lastSuccessfulFetch = _usageService.lastSuccessfulFetch;
        _trackedAppsFound = data.length;
        _totalTrackedMinutes = totalMinutes.round();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _lastCheckAt = now;
        _loading = false;
      });
    }
  }

  Future<void> _openUsageSettings() async {
    await _usageService.openUsageSettings();
  }

  String _fmt(DateTime? value) {
    if (value == null) return 'Not available';
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:${value.second.toString().padLeft(2, '0')}';
  }

  Widget _statusRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: valueColor ?? Colors.black87),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissionColor = _hasPermission ? const Color(0xFF0A7A3E) : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics'),
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _runDiagnostics,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Android Compatibility Check',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Use this screen on each phone to confirm permission, data collection, and update timing.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _statusRow(
                            'Usage access permission',
                            _hasPermission ? 'Granted' : 'Not granted',
                            valueColor: permissionColor,
                          ),
                          _statusRow('Tracked apps found today', '$_trackedAppsFound'),
                          _statusRow('Total tracked minutes today', '$_totalTrackedMinutes'),
                          _statusRow('Last check time', _fmt(_lastCheckAt)),
                          _statusRow('Last successful fetch', _fmt(_lastSuccessfulFetch)),
                          if (_error.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Last error: $_error',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFFF4F8FF),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OEM Tips (Xiaomi, OnePlus, vivo, OPPO, realme)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1) Disable battery optimization for this app.'),
                    Text('2) Keep Usage Access enabled after reboot.'),
                    Text('3) Open and close social apps once to refresh stats.'),
                    Text('4) Wait 5-10 minutes for delayed ROM updates.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _runDiagnostics,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Run Check'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openUsageSettings,
                    icon: const Icon(Icons.settings),
                    label: const Text('Open Usage Settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
