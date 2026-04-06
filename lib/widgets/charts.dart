import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SocialMediaPieChart extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> usageDataByPeriod;

  const SocialMediaPieChart({Key? key, required this.usageDataByPeriod})
      : super(key: key);

  @override
  State<SocialMediaPieChart> createState() => _SocialMediaPieChartState();
}

class _SocialMediaPieChartState extends State<SocialMediaPieChart>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _touchedIndex = -1;

  static const Map<String, Color> appColors = {
    'com.google.android.youtube': Color(0xFFADD8E6), // Light Blue
    'tv.twitch.android.app': Color(0xFFFFB6C1), // Light Pink
    'com.twitter.android': Color(0xFF87CEFA), // Sky Blue
    'com.linkedin.android': Color(0xFFB0E0E6), // Powder Blue
    'com.facebook.katana': Color(0xFFFFA07A), // Light Salmon
    'com.snapchat.android': Color(0xFFFFFF99), // Light Yellow
    'com.instagram.android': Color(0xFFFFDAB9), // Peach Puff
    'com.pinterest': Color(0xFFD8BFD8), // Thistle
    'com.reddit.frontpage': Color(0xFFFF9999), // Light Coral
    'com.zhiliaoapp.musically': Color(0xFF98FB98), // Pale Green (TikTok)
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly'),
          ],
          labelColor: Colors.black,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildChartView(widget.usageDataByPeriod['weekly'] ?? []),
              _buildChartView(widget.usageDataByPeriod['monthly'] ?? []),
              _buildChartView(widget.usageDataByPeriod['yearly'] ?? []),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartView(List<Map<String, dynamic>> usageData) {
    if (usageData.isEmpty) {
      return const Center(child: Text('No data available.'));
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pie chart
          _buildPieChart(usageData),
          const SizedBox(height: 16),
          // Legend
          _buildLegend(usageData),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<Map<String, dynamic>> usageData) {
    double totalCO2 = usageData.fold(0.0, (sum, data) => sum + (data['co2'] as double));

    final sections = usageData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final co2 = data['co2'] as double;
      final percentage = totalCO2 > 0 ? (co2 / totalCO2) * 100 : 0;
      final packageName = data['package'] as String;
      final color = appColors[packageName] ?? Colors.grey;

      return PieChartSectionData(
        value: co2,
        title: "${percentage.toStringAsFixed(1)}%",
        color: color,
        radius: index == _touchedIndex ? 95 : 80, // Animation on tap
        titleStyle: const TextStyle(color: Colors.white, fontSize: 14),
      );
    }).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: screenWidth * 0.8,
      height: screenWidth * 0.8,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              setState(() {
                if (response == null || response.touchedSection == null) {
                  _touchedIndex = -1;
                  return;
                }
                _touchedIndex = response.touchedSection!.touchedSectionIndex;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(List<Map<String, dynamic>> usageData) {
    final screenWidth = MediaQuery.of(context).size.width;
    double totalCO2 = usageData.fold(0.0, (sum, data) => sum + (data['co2'] as double));

    return Container(
      padding: const EdgeInsets.all(16.0),
      width: screenWidth * 0.8,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: usageData.map((data) {
          final packageName = data['package'] as String;
          final appName = _getAppName(packageName);
          final color = appColors[packageName] ?? Colors.grey;
          final co2 = data['co2'] as double;
          final percentage = totalCO2 > 0 ? (co2 / totalCO2) * 100 : 0;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$appName (${percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _getAppName(String packageName) {
    const packageToName = {
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

    return packageToName[packageName] ?? packageName;
  }
}
