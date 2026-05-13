import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Placeholder imports for tabs
import 'home/home_tab.dart';
import 'prediction/prediction_results_screen.dart'; // or college tab
import 'wishlist/wishlist_tab.dart';
import 'analytics/analytics_tab.dart';
import 'profile/profile_tab.dart';
import 'premium/premium_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const PredictionResultsScreen(), // We'll use this as the Colleges tab for now
    const PremiumScreen(),
    const AnalyticsTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.home),
              activeIcon: Icon(LucideIcons.home, fill: 1.0), // Lucide doesn't have fill natively, but we'll stick to basic icons or just use the same
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.building2),
              label: 'Colleges',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.crown),
              label: 'Premium',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.barChart2),
              label: 'Cutoffs',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.user),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
