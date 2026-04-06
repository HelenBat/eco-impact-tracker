import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsageService {
  static final UsageService _instance = UsageService._internal();
  factory UsageService() => _instance;
  UsageService._internal();

  static const _channel = MethodChannel('eco_impact_app/usage');
  
  DateTime? _resetTime;
  Map<String, double> _dailyOffset = {};
  DateTime? _lastSuccessfulFetch;

  final Map<String, double> co2PerMinute = {
    'com.google.android.youtube': 0.46,
    'tv.twitch.android.app': 0.55,
    'com.twitter.android': 0.60,
    'com.linkedin.android': 0.71,
    'com.facebook.katana': 0.79,
    'com.snapchat.android': 0.87,
    'com.instagram.android': 1.05,
    'com.pinterest': 1.30,
    'com.reddit.frontpage': 2.48,
    'com.zhiliaoapp.musically': 2.63,
  };

  final Map<String, double> energyPerMinute = {
    'com.google.android.youtube': 8.58,
    'tv.twitch.android.app': 9.05,
    'com.twitter.android': 10.28,
    'com.linkedin.android': 8.92,
    'com.facebook.katana': 12.36,
    'com.snapchat.android': 11.48,
    'com.instagram.android': 8.90,
    'com.pinterest': 10.83,
    'com.reddit.frontpage': 11.04,
    'com.zhiliaoapp.musically': 15.81,
  };

  final Map<String, String> packageAliases = {
    'com.facebook.lite': 'com.facebook.katana',
    'com.instagram.lite': 'com.instagram.android',
    'com.ss.android.ugc.trill': 'com.zhiliaoapp.musically',
    'com.zhiliaoapp.musically.go': 'com.zhiliaoapp.musically',
    'com.twitter.android.lite': 'com.twitter.android',
    'com.google.android.apps.youtube.music': 'com.google.android.youtube',
  };

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    int? ts = prefs.getInt('reset_timestamp');
    if (ts != null) _resetTime = DateTime.fromMillisecondsSinceEpoch(ts);

    String? offsetJson = prefs.getString('daily_offset_map');
    if (offsetJson != null) {
      try {
        Map<String, dynamic> decoded = json.decode(offsetJson);
        _dailyOffset = decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
        debugPrint("♻️ Loaded Daily Offset: $_dailyOffset");
      } catch (e) {
        debugPrint("❌ Error parsing offset: $e");
      }
    }
  }

  /// RESET: Capture Morning Usage (Midnight -> Now) and save it.
  Future<void> resetStatistics() async {
    final now = DateTime.now();
    _resetTime = now;
    
    // Fetch from Midnight to Now
    final startOfDay = DateTime(now.year, now.month, now.day);
    List<Map<String, dynamic>> morningRaw = await _fetchRawData(startOfDay, now);

    _dailyOffset = {};
    for (var app in morningRaw) {
      String pkg = app['package'];
      double mins = (app['minutes'] as num).toDouble();
      _dailyOffset[pkg] = (_dailyOffset[pkg] ?? 0.0) + mins;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reset_timestamp', now.millisecondsSinceEpoch);
    await prefs.setString('daily_offset_map', json.encode(_dailyOffset));

    debugPrint("🧹 Reset Done. Hidden Morning Usage: $_dailyOffset");
  }

  Future<List<Map<String, dynamic>>> getTodayUsage() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return getRangeUsage(start: start, end: now);
  }

  Future<List<Map<String, dynamic>>> getRangeUsage({
    required DateTime start, 
    required DateTime end
  }) async {
    if (_resetTime == null) await init();

    DateTime effectiveStart = start;
    bool shouldSubtractOffset = false;

    // --- CRITICAL FIX ---
    // If the Reset Time is newer than the Start Time, we need to hide history.
    if (_resetTime != null && start.isBefore(_resetTime!)) {
       
       // 1. Move the start time to the "Midnight of the Reset Day".
       // Why Midnight? Because Android stores data in daily buckets. 
       // If we ask for 14:00, Android gets confused. If we ask for 00:00, we get the whole bucket.
       effectiveStart = DateTime(_resetTime!.year, _resetTime!.month, _resetTime!.day);
       
       // 2. Since we are fetching the whole day (including morning), 
       // we MUST enable subtraction to hide that morning data.
       shouldSubtractOffset = true;
    } 
    else if (_resetTime != null) {
       // Even if we are asking for a future date (Tomorrow), check if it's the SAME day as reset.
       final isSameDay = (effectiveStart.year == _resetTime!.year && 
                          effectiveStart.month == _resetTime!.month && 
                          effectiveStart.day == _resetTime!.day);
       if (isSameDay) {
         shouldSubtractOffset = true;
       }
    }

    // Double check: If the "Midnight of Reset Day" is still after the requested End time, return empty.
    if (effectiveStart.isAfter(end)) return [];

    // Fetch Data
    List<Map<String, dynamic>> rawList = await _fetchRawData(effectiveStart, end);

    // Aggregate (Handle duplicates from native)
    Map<String, double> aggregatedMap = {};
    for (var app in rawList) {
      String pkg = _normalizePackage(app['package'].toString());
      double mins = (app['minutes'] as num).toDouble();
      aggregatedMap[pkg] = (aggregatedMap[pkg] ?? 0.0) + mins;
    }

    // Subtract Offset
    List<Map<String, dynamic>> finalResult = [];
    
    aggregatedMap.forEach((pkg, totalMinutes) {
      double subtractAmount = 0.0;
      
      if (shouldSubtractOffset) {
        subtractAmount = _dailyOffset[pkg] ?? 0.0;
      }

      double netMinutes = totalMinutes - subtractAmount;

      // Noise Filter (ignore -0.001)
      if (netMinutes < 0.1) netMinutes = 0;

      if (netMinutes > 0) {
        finalResult.add({
          'package': pkg,
          'minutes': netMinutes,
          'co2': netMinutes * (co2PerMinute[pkg] ?? 0.0),
          'energy': netMinutes * (energyPerMinute[pkg] ?? 0.0),
        });
      }
    });

    _lastSuccessfulFetch = DateTime.now();
    return finalResult;
  }

  String _normalizePackage(String packageName) {
    return packageAliases[packageName] ?? packageName;
  }

  Future<bool> hasUsagePermission() async {
    try {
      final bool result = await _channel.invokeMethod('hasUsagePermission');
      return result;
    } catch (e) {
      debugPrint("❌ Error checking permission in service: $e");
      return false;
    }
  }

  Future<void> openUsageSettings() async {
    try {
      await _channel.invokeMethod('openUsageSettings');
    } catch (e) {
      debugPrint("❌ Error opening usage settings in service: $e");
    }
  }

  DateTime? get lastSuccessfulFetch => _lastSuccessfulFetch;

  Future<List<Map<String, dynamic>>> _fetchRawData(DateTime start, DateTime end) async {
    try {
      final String result = await _channel.invokeMethod('getRangeUsage', {
        'startTime': start.millisecondsSinceEpoch,
        'endTime': end.millisecondsSinceEpoch,
      });

      if (result.trim().isEmpty) return [];

      final dynamic decoded = json.decode(result);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      debugPrint("❌ Error fetching raw usage: $e");
      return [];
    }
  }
}