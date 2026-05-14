import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'icon': LucideIcons.bellRing,
      'iconColor': Colors.blue,
      'title': 'Round 2 Results Out!',
      'description': 'The CSAS Round 2 seat allocation list has been released. Check your dashboard now to see if you have been allotted a seat in your preferred college.',
      'fullDetails': 'DU has released the second round of allocations for 71,000+ seats. You have until August 30th to accept the allocation. Failure to accept will result in removal from the CSAS process.',
      'time': '2h ago',
      'isUnread': true,
    },
    {
      'id': 2,
      'icon': LucideIcons.sparkles,
      'iconColor': Colors.purple,
      'title': '99% Accuracy Reached',
      'description': 'Our AI model has been updated with the latest data from Day 3 of admissions.',
      'fullDetails': 'Based on the latest trends in B.Com (Hons) and Economics (Hons), our prediction accuracy has improved significantly. We recommend re-checking your "High Chance" college list.',
      'time': '5h ago',
      'isUnread': true,
    },
    {
      'id': 3,
      'icon': LucideIcons.info,
      'iconColor': Colors.orange,
      'title': 'Payment Successful',
      'description': 'Your Premium Season Pass has been activated. Enjoy all features!',
      'fullDetails': 'You now have access to Detailed Cutoff Trends, AI Choice Filling Assistant, and Direct Mentor Support for the entire 2026 session.',
      'time': '1d ago',
      'isUnread': false,
    },
    {
      'id': 4,
      'icon': LucideIcons.heart,
      'iconColor': Colors.red,
      'title': 'College Added to Wishlist',
      'description': 'Hindu College - B.A. (Hons.) Economics has been added to your preference list.',
      'fullDetails': 'This college has consistently ranked #1 in NIRF. Your current score puts you in the "Medium Chance" category for this specific program.',
      'time': '1d ago',
      'isUnread': false,
    },
    {
      'id': 5,
      'icon': LucideIcons.userPlus,
      'iconColor': Colors.green,
      'title': 'Welcome to CUET Predictor!',
      'description': 'Complete your profile to get more accurate college recommendations.',
      'fullDetails': 'By providing your category (EWS/OBC/SC/ST) and gender details, we can refine our results by up to 40% accuracy.',
      'time': '3d ago',
      'isUnread': false,
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n['isUnread'] = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.checkCheck, size: 20),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('Recent'),
          ..._notifications.map((n) => _NotificationItem(
                notification: n,
                onRead: () => setState(() => n['isUnread'] = false),
              )),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _NotificationItem extends StatefulWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onRead;

  const _NotificationItem({required this.notification, required this.onRead});

  @override
  State<_NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<_NotificationItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final n = widget.notification;
    final isUnread = n['isUnread'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark 
            ? (isUnread ? Colors.white.withOpacity(0.08) : const Color(0xFF161C24))
            : (isUnread ? theme.colorScheme.primary.withOpacity(0.05) : Colors.white),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isUnread 
              ? theme.colorScheme.primary.withOpacity(0.3) 
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        ),
        boxShadow: [
          if (!isDark && !isUnread)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
            if (isUnread) widget.onRead();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon with unread dot
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: n['iconColor'].withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(n['icon'], color: n['iconColor'], size: 20),
                        ),
                        if (isUnread)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? const Color(0xFF161C24) : Colors.white, width: 2),
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
                                  n['title'],
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                n['time'],
                                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n['description'],
                            maxLines: _isExpanded ? 10 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ],
                ),
                // Expanded Content
                if (_isExpanded) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  Text(
                    n['fullDetails'],
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                        ),
                        child: Text(
                          'View Details',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isExpanded = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          foregroundColor: theme.colorScheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Dismiss',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
