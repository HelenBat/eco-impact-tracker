package com.helenbatu.ecoimpactapp;

import android.app.AppOpsManager;
import android.app.usage.UsageStats;
import android.app.usage.UsageStatsManager;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;



public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "eco_impact_app/usage"; // ✅ Updated channel name

    // Map for CO₂ emissions (grams per minute)
    private static final Map<String, Double> SOCIAL_MEDIA_CO2_MAP = new HashMap<String, Double>() {{
        put("com.google.android.youtube", 0.46);
        put("tv.twitch.android.app", 0.55);
        put("com.twitter.android", 0.60);
        put("com.linkedin.android", 0.71);
        put("com.facebook.katana", 0.79);
        put("com.snapchat.android", 0.87);
        put("com.instagram.android", 1.05);
        put("com.pinterest", 1.30);
        put("com.reddit.frontpage", 2.48);
        put("com.zhiliaoapp.musically", 2.63);
    }};

    // Map for energy consumption (mAh per minute)
    private static final Map<String, Double> SOCIAL_MEDIA_ENERGY_MAP = new HashMap<String, Double>() {{
        put("com.google.android.youtube", 8.58);
        put("tv.twitch.android.app", 9.05);
        put("com.twitter.android", 10.28);
        put("com.linkedin.android", 8.92);
        put("com.facebook.katana", 12.36);
        put("com.snapchat.android", 11.48);
        put("com.instagram.android", 8.90);
        put("com.pinterest", 10.83);
        put("com.reddit.frontpage", 11.04);
        put("com.zhiliaoapp.musically", 15.81);
    }};

    // Map known alternate package IDs to canonical IDs used by this app.
    private static final Map<String, String> PACKAGE_ALIASES = new HashMap<String, String>() {{
        put("com.facebook.lite", "com.facebook.katana");
        put("com.instagram.lite", "com.instagram.android");
        put("com.ss.android.ugc.trill", "com.zhiliaoapp.musically");
        put("com.zhiliaoapp.musically.go", "com.zhiliaoapp.musically");
        put("com.twitter.android.lite", "com.twitter.android");
        put("com.google.android.apps.youtube.music", "com.google.android.youtube");
    }};

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "getDailyUsage":
                            result.success(getDailyUsageStats());
                            break;
                        case "getRangeUsage":
                            Long startTime = call.argument("startTime");
                            Long endTime = call.argument("endTime");
                            if (startTime == null || endTime == null) {
                                result.error("INVALID_ARGS", "startTime/endTime is required", null);
                                break;
                            }
                            result.success(getRangeUsageStats(startTime, endTime));
                            break;
                        case "hasUsagePermission":
                            boolean hasPermission = hasUsageStatsPermission(this);
                            Log.d("UsagePermission", "hasUsageStatsPermission: " + hasPermission);
                            result.success(hasPermission);
                            break;
                        case "openUsageSettings":
                            openUsageAccessSettings();
                            result.success(null);
                            break;
                        default:
                            result.notImplemented();
                            break;
                    }
                });
    }

    // ---------------------------
    //  Permission Check Methods
    // ---------------------------

    private static boolean hasUsageStatsPermission(Context context) {
        AppOpsManager appOps = (AppOpsManager) context.getSystemService(Context.APP_OPS_SERVICE);
        if (appOps == null) {
            return false;
        }

        int mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                context.getPackageName());
    
        Log.d("UsagePermission", "Permission Mode: " + mode);
    
        if (mode == AppOpsManager.MODE_ALLOWED) {
            Log.d("UsagePermission", "✅ Permission granted!");
            return true;
        } else if (mode == AppOpsManager.MODE_IGNORED) {
            Log.e("UsagePermission", "❌ Permission ignored! The user likely denied it.");
        } else if (mode == AppOpsManager.MODE_DEFAULT) {
            // On some OEM ROMs MODE_DEFAULT still behaves as allowed when usage data exists.
            UsageStatsManager usageStatsManager =
                    (UsageStatsManager) context.getSystemService(Context.USAGE_STATS_SERVICE);
            if (usageStatsManager != null) {
                long end = System.currentTimeMillis();
                long start = end - (60L * 60L * 1000L);
                List<UsageStats> stats = usageStatsManager.queryUsageStats(
                        UsageStatsManager.INTERVAL_DAILY, start, end);
                boolean hasData = stats != null && !stats.isEmpty();
                if (hasData) {
                    return true;
                }
            }
            Log.e("UsagePermission", "⚠️ Permission in default state! Asking user to enable manually.");
            return false;
        } else {
            Log.e("UsagePermission", "❌ Unknown permission mode: " + mode);
        }
    
        return false;
    }
    


    private void openUsageAccessSettings() {
        Log.d("UsagePermission", "🚀 Forcing open Usage Access Settings...");

        Intent intent = new Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

        try {
            startActivity(intent);
            Log.d("UsagePermission", "✅ Settings page opened successfully.");
        } catch (Exception e) {
            Log.e("UsagePermission", "❌ Failed to open usage settings: " + e.getMessage());
            try {
                Intent appDetailsIntent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
                appDetailsIntent.setData(Uri.parse("package:" + getPackageName()));
                appDetailsIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(appDetailsIntent);
                Log.d("UsagePermission", "✅ Opened app details settings as fallback.");
            } catch (Exception fallbackError) {
                Log.e("UsagePermission", "❌ Failed to open fallback settings: " + fallbackError.getMessage());
            }
        }
    }

    // ---------------------------
    //  Usage Stats Methods
    // ---------------------------

    private String getDailyUsageStats() {
        Calendar calendar = Calendar.getInstance();
        long endTime = calendar.getTimeInMillis();

        calendar.set(Calendar.HOUR_OF_DAY, 0);
        calendar.set(Calendar.MINUTE, 0);
        calendar.set(Calendar.SECOND, 0);
        calendar.set(Calendar.MILLISECOND, 0);
        long startTime = calendar.getTimeInMillis();

        return getUsageFormatted(startTime, endTime);
    }

    private String getRangeUsageStats(long startTime, long endTime) {
        return getUsageFormatted(startTime, endTime);
    }

    @SuppressWarnings("NewApi")
    private String getUsageFormatted(long startTime, long endTime) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            return "[]";
        }

        UsageStatsManager usageStatsManager =
                (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        List<UsageStats> stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY, startTime, endTime);

        if (stats == null || stats.isEmpty()) {
            return "[]";
        }

        HashMap<String, Long> appForegroundTimeMap = new HashMap<>();
        for (UsageStats usage : stats) {
            String packageName = usage.getPackageName();
            String canonicalPackage = PACKAGE_ALIASES.getOrDefault(packageName, packageName);
            if (SOCIAL_MEDIA_CO2_MAP.containsKey(canonicalPackage)) {
                long totalForegroundTime = usage.getTotalTimeInForeground();
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                    appForegroundTimeMap.put(
                            canonicalPackage,
                            appForegroundTimeMap.getOrDefault(canonicalPackage, 0L) + totalForegroundTime
                    );
                }
            }
        }

        List<String> usageResults = new ArrayList<>();
        for (Map.Entry<String, Long> entry : appForegroundTimeMap.entrySet()) {
            String packageName = entry.getKey();
            long totalMs = entry.getValue();
            double totalMinutes = totalMs / 60000.0;

            double co2PerMinute = SOCIAL_MEDIA_CO2_MAP.get(packageName);
            double totalCO2 = totalMinutes * co2PerMinute;

            double energyPerMinute = SOCIAL_MEDIA_ENERGY_MAP.get(packageName);
            double totalEnergy = totalMinutes * energyPerMinute;

            usageResults.add(String.format(
                    Locale.US,
                    "{\"package\":\"%s\",\"minutes\":%.2f,\"co2\":%.2f,\"energy\":%.2f}",
                    packageName, totalMinutes, totalCO2, totalEnergy
            ));
        }

        return "[" + String.join(",", usageResults) + "]";
    }
}
