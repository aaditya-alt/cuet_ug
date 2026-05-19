import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/navigation_provider.dart';
import '../providers/auth_service.dart';
import 'auth/login_screen.dart';

// Placeholder imports for tabs
import 'home/home_tab.dart';
import 'prediction/prediction_results_screen.dart';
import 'prediction/du_input_screen.dart';
import 'prediction/du_college_discovery_screen.dart';
import 'wishlist/wishlist_tab.dart';
import 'analytics/analytics_tab.dart';
import 'profile/profile_tab.dart';
import 'premium/premium_screen.dart';
import 'community/community_hub_screen.dart';
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

  void _showMainAuthGuard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161C24) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.lock,
                  color: theme.colorScheme.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Unlock Forum Discussions 💬',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Interact with fellow DU aspirants in real-time, ask admission queries, and access specialized peer community forums by signing in.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Sign In / Create Account',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Maybe Later',
                  style: GoogleFonts.outfit(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    final appSettings = Provider.of<AppSettingsProvider>(context);

    // Build tabs dynamically based on admin config
    final List<Widget> activeTabs = [
      const HomeTab(),
      const DuCollegeDiscoveryScreen(),
      const CommunityHubScreen(),
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
            if (index == 2) {
              final authService = Provider.of<AuthService>(context, listen: false);
              if (!authService.isAuthenticated) {
                _showMainAuthGuard(context);
                return;
              }
            }
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
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.users),
              label: 'Community',
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
