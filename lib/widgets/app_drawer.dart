// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  // Define the custom green color.
  static const Color customGreen = Color(0xFF00AB66);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Updated Drawer Header with custom green background and white text.
          SizedBox(
            height: 100,
            child: DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.only(left: 16),
              decoration: const BoxDecoration(
                color: customGreen,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Menu',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Home
          ListTile(
            leading: const Icon(Icons.home, color: customGreen),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          // Stats
          ListTile(
            leading: const Icon(Icons.show_chart, color: customGreen),
            title: const Text('Usage Statistics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/stats');
            },
          ),
          // Total Impact
          ListTile(
            leading: const Icon(Icons.assessment, color: customGreen),
            title: const Text('Total Impact'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/totalImpact');
            },
          ),
          // Analysis
          ListTile(
            leading: const Icon(Icons.insights, color: customGreen),
            title: const Text('Analysis'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/analysis');
            },
          ),
          // Diagnostics
          ListTile(
            leading: const Icon(Icons.medical_information, color: customGreen),
            title: const Text('Diagnostics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/diagnostics');
            },
          ),
          // About
          ListTile(
            leading: const Icon(Icons.info, color: customGreen),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/about');
            },
          ),
        ],
      ),
    );
  }
}
