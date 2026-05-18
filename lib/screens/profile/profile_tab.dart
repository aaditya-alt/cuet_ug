import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../auth_screen.dart';
import '../../main.dart'; // For ThemeProvider
import '../wishlist/wishlist_tab.dart';
import '../notifications/notification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../admin/admin_login_screen.dart';
import '../admin/admin_dashboard.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_service.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);

    final user = authService.currentUser;
    final isGuest = user == null;
    final userName = user?.userMetadata?['full_name'] ?? 'Student';
    final userEmail = user?.email ?? 'No email available';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.user,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isGuest ? 'Guest User' : userName,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isGuest ? 'Sign in to sync your data' : userEmail,
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Settings List
            _buildSectionHeader('Preferences'),
            _buildListTile(
              context,
              icon: LucideIcons.palette,
              title: 'App Theme',
              trailing: DropdownButton<ThemeMode>(
                value: themeProvider.themeMode,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                ],
                onChanged: (mode) {
                  if (mode != null) themeProvider.setThemeMode(mode);
                },
              ),
            ),
            _buildListTile(
              context,
              icon: LucideIcons.bell,
              title: 'Notifications',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
            ),
            _buildListTile(
              context,
              icon: LucideIcons.heart,
              title: 'My Wishlist',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WishlistTab()),
                );
              },
            ),
            _buildListTile(
              context,
              icon: LucideIcons.shieldAlert,
              title: 'Admin Portal',
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                final isAdmin = prefs.getBool('is_admin_logged_in') ?? false;
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => isAdmin
                          ? const AdminDashboard()
                          : const AdminLoginScreen(),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Account'),
            _buildListTile(
              context,
              icon: LucideIcons.shield,
              title: 'Privacy & Security',
              onTap: () => _showMockBottomSheet(
                context,
                LucideIcons.shield,
                'Privacy & Security',
                'Your data is protected with end-to-end encryption. We never share your scores with third parties without your permission.\n\n• Biometric Lock: Enabled\n• Data Sync: Active\n• Privacy Mode: Standard',
              ),
            ),
            _buildListTile(
              context,
              icon: LucideIcons.helpCircle,
              title: 'Help & Support',
              onTap: () => _showMockBottomSheet(
                context,
                LucideIcons.helpCircle,
                'Help & Support',
                'Need help with your preference list or scores?\n\n• Email: login@collegemitra.net.in\n• Response Time: < 2 Hours\n• FAQ: Frequently Asked Questions',
              ),
            ),
            if (!isGuest)
              _buildListTile(
                context,
                icon: LucideIcons.logOut,
                title: 'Log Out',
                color: Colors.red,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Log Out?'),
                      content: const Text(
                        'Are you sure you want to log out of your account?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await authService.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const AuthScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          child: const Text(
                            'Log Out',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            if (isGuest)
              _buildListTile(
                context,
                icon: LucideIcons.logIn,
                title: 'Sign In',
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                    (route) => false,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showMockBottomSheet(
    BuildContext context,
    IconData icon,
    String title,
    String content,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              content,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: color ?? theme.iconTheme.color),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        trailing:
            trailing ??
            const Icon(LucideIcons.chevronRight, size: 20, color: Colors.grey),
        onTap: onTap ?? (trailing == null ? () {} : null),
      ),
    );
  }
}
