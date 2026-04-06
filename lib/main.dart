import 'package:flutter/material.dart';
// Import custom services
import 'package:eco_impact_app/services/usage_service.dart';

// Import app pages
import 'pages/home_page.dart';
import 'pages/stats_page.dart';
import 'pages/total_impact_page.dart';
import 'pages/about_page.dart';
import 'pages/analysis_page.dart';
import 'pages/diagnostics_page.dart';
import 'screens/permission_check_screen.dart';


/// MAIN ENTRY POINT
void main() async {
  // Ensure plugins + framework are initialized
  WidgetsFlutterBinding.ensureInitialized();
  await UsageService().init();


  // 4) Finally, run your app
  runApp(const EcoImpactApp());
}

/// BACKGROUND TASK HANDLER (Top-level function)
/// This is called even when the app is closed or in the background,
/// on a schedule set by WorkManager.


/// The main Flutter App class
class EcoImpactApp extends StatelessWidget {
  const EcoImpactApp({Key? key}) : super(key: key);

  static const Color customGreen = Color(0xFF00AB66);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Media Carbon Footprint',
      theme: ThemeData(
        fontFamily: 'Titillium',
        scaffoldBackgroundColor: Colors.white,
        primaryColor: customGreen,
        appBarTheme: const AppBarTheme(
          backgroundColor: customGreen,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: customGreen,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const PermissionCheckScreen(),
        '/home': (context) => const HomePage(),
        '/stats': (context) => const StatsPage(),
        '/totalImpact': (context) => const TotalImpactPage(),
        '/about': (context) => const AboutPage(),
        '/analysis': (context) => const AnalysisPage(),
        '/diagnostics': (context) => const DiagnosticsPage(),
      },
    );
  }
}
