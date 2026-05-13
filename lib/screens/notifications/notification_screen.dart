import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.checkCheck, size: 20),
            onPressed: () {},
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('Today'),
          _buildNotificationItem(
            context,
            icon: LucideIcons.bellRing,
            iconColor: Colors.blue,
            title: 'Round 2 Results Out!',
            description: 'The CSAS Round 2 seat allocation list has been released. Check your dashboard now.',
            time: '2h ago',
            isUnread: true,
          ),
          _buildNotificationItem(
            context,
            icon: LucideIcons.sparkles,
            iconColor: Colors.purple,
            title: '99% Accuracy Reached',
            description: 'Our AI model has been updated with the latest data from Day 3 of admissions.',
            time: '5h ago',
            isUnread: true,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Yesterday'),
          _buildNotificationItem(
            context,
            icon: LucideIcons.info,
            iconColor: Colors.orange,
            title: 'Payment Successful',
            description: 'Your Premium Season Pass has been activated. Enjoy all features!',
            time: '1d ago',
            isUnread: false,
          ),
          _buildNotificationItem(
            context,
            icon: LucideIcons.heart,
            iconColor: Colors.red,
            title: 'College Added to Wishlist',
            description: 'Hindu College - B.A. (Hons.) Economics has been added to your preference list.',
            time: '1d ago',
            isUnread: false,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Earlier'),
          _buildNotificationItem(
            context,
            icon: LucideIcons.userPlus,
            iconColor: Colors.green,
            title: 'Welcome to CUET Predictor!',
            description: 'Complete your profile to get more accurate college recommendations.',
            time: '3d ago',
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String time,
    required bool isUnread,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? (isUnread ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.03))
            : (isUnread ? theme.colorScheme.primary.withOpacity(0.05) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnread 
              ? theme.colorScheme.primary.withOpacity(0.2) 
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (isUnread)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
