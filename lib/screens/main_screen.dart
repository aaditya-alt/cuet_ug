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
import '../providers/app_settings_provider.dart';
import '../main.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingLink = MyApp.pendingDeepLink;
      if (pendingLink != null) {
        MyApp.pendingDeepLink = null;
        MyApp.handleRawLink(pendingLink);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    final appSettings = Provider.of<AppSettingsProvider>(context);

    // Build tabs dynamically based on admin config
    final List<Widget> activeTabs = [
      const HomeTab(),
      const DuCollegeDiscoveryScreen(),
      if (appSettings.premiumEnabled) const PremiumScreen(),
      const ProfileTab(),
    ];

    // Safely clamp/validate index
    int activeIndex = navProvider.currentIndex;
    if (activeIndex >= activeTabs.length) {
      activeIndex = activeTabs.length - 1;
      // Schedule to run after the current frame to update provider index
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navProvider.setIndex(activeIndex);
      });
    }

    return Scaffold(
      body: IndexedStack(index: activeIndex, children: activeTabs),
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
          currentIndex: activeIndex,
          onTap: (index) {
            navProvider.setIndex(index);
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.building2),
              label: 'Colleges',
            ),
            if (appSettings.premiumEnabled)
              const BottomNavigationBarItem(
                icon: Icon(LucideIcons.crown),
                label: 'Premium',
              ),
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.user),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
