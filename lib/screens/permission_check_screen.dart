import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PermissionCheckScreen extends StatefulWidget {
  const PermissionCheckScreen({Key? key}) : super(key: key);

  @override
  State<PermissionCheckScreen> createState() => _PermissionCheckScreenState();
}

class _PermissionCheckScreenState extends State<PermissionCheckScreen>
    with WidgetsBindingObserver {
  static const MethodChannel _channel =
      MethodChannel('eco_impact_app/usage');

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndPrompt();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called whenever the app resumes from background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // Re-check usage permission when returning from Settings
      _checkPermissionAndPrompt();
    }
  }

  Future<void> _checkPermissionAndPrompt() async {
    debugPrint("🔍 Checking permission...");
    bool hasPerm = await _hasUsagePermissionNative();
    debugPrint("✅ Permission status: $hasPerm");

    if (!mounted) return;

    if (!hasPerm) {
      debugPrint("⚠️ Permission missing.");
    } else {
      debugPrint("🚀 Permission granted! Navigating to Home...");
      _navigateToHome();
    }
  }


  Future<bool> _hasUsagePermissionNative() async {
    try {
      final bool result = await _channel.invokeMethod('hasUsagePermission');
      return result;
    } catch (e) {
      debugPrint("Error checking usage permission: $e");
      return false;
    }
  }

  void _navigateToHome() {
    if (!mounted || _isNavigating) return;
    _isNavigating = true;
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _openUsageSettings() async {
    try {
      await _channel.invokeMethod('openUsageSettings');
    } catch (e) {
      debugPrint("Error opening usage settings: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage Permission Check'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enable Usage Access',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'This permission is required to read social media screen time and calculate impact.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFFF4F8FF),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OEM Tips',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1) Xiaomi/MIUI: disable battery optimization for this app.'),
                    Text('2) OnePlus/realme/OPPO/vivo: allow auto-start/background activity.'),
                    Text('3) Open and close a social app once, then wait 5-10 minutes.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openUsageSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Open Usage Settings'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _checkPermissionAndPrompt,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('I Enabled It - Recheck'),
              ),
            ),
            const Spacer(),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
