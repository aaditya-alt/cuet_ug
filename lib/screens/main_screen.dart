import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';

// Placeholder imports for tabs
import 'home/home_tab.dart';
import 'prediction/prediction_results_screen.dart'; 
import 'prediction/du_input_screen.dart';
import 'prediction/du_college_discovery_screen.dart';
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
  final List<Widget> _tabs = [
    const HomeTab(),
    const DuCollegeDiscoveryScreen(), 
    const PremiumScreen(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);

    return Scaffold(
      body: IndexedStack(
        index: navProvider.currentIndex,
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
          currentIndex: navProvider.currentIndex,
          onTap: (index) {
            navProvider.setIndex(index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.home),
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
              icon: Icon(LucideIcons.user),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
