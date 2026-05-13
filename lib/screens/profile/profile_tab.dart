import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../main.dart'; // For ThemeProvider
import '../wishlist/wishlist_tab.dart';
import '../notifications/notification_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(icon: const Icon(LucideIcons.settings), onPressed: () {}),
        ],
      ),
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
                      border: Border.all(color: theme.colorScheme.primary, width: 2),
                    ),
                    child: Icon(LucideIcons.user, size: 40, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Abhinav',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'abhinav@example.com',
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
                  DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
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
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
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
            _buildListTile(context, icon: LucideIcons.bookmark, title: 'Saved Colleges'),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Account'),
            _buildListTile(context, icon: LucideIcons.shield, title: 'Privacy & Security'),
            _buildListTile(context, icon: LucideIcons.helpCircle, title: 'Help & Support'),
            _buildListTile(context, icon: LucideIcons.logOut, title: 'Log Out', color: Colors.red),
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
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, {required IconData icon, required String title, Widget? trailing, Color? color, VoidCallback? onTap}) {
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
        trailing: trailing ?? const Icon(LucideIcons.chevronRight, size: 20, color: Colors.grey),
        onTap: onTap ?? (trailing == null ? () {} : null),
      ),
    );
  }
}
