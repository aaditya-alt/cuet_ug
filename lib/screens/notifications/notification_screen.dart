import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh notifications when entering the screen
    Future.microtask(() {
      if (mounted) {
        Provider.of<NotificationService>(context, listen: false).fetchNotifications();
      }
    });
  }

  IconData _getIconForNotification(String title, String desc) {
    final t = title.toLowerCase();
    final d = desc.toLowerCase();
    if (t.contains('result') || t.contains('cutoff') || t.contains('csas') || t.contains('round')) {
      return LucideIcons.bellRing;
    } else if (t.contains('accuracy') || t.contains('model') || t.contains('update') || t.contains('guide')) {
      return LucideIcons.sparkles;
    } else if (t.contains('payment') || t.contains('premium') || t.contains('crown')) {
      return LucideIcons.crown;
    } else if (t.contains('wishlist') || t.contains('favorite') || t.contains('heart')) {
      return LucideIcons.heart;
    }
    return LucideIcons.info;
  }

  Color _getIconColorForNotification(String title) {
    final t = title.toLowerCase();
    if (t.contains('result') || t.contains('cutoff') || t.contains('csas') || t.contains('round')) {
      return Colors.blue;
    } else if (t.contains('accuracy') || t.contains('model') || t.contains('update') || t.contains('guide')) {
      return Colors.purple;
    } else if (t.contains('payment') || t.contains('premium') || t.contains('crown')) {
      return Colors.orange;
    } else if (t.contains('wishlist') || t.contains('favorite') || t.contains('heart')) {
      return Colors.red;
    }
    return Colors.teal;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notificationService = Provider.of<NotificationService>(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (notificationService.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.checkCheck, size: 20),
              onPressed: () {
                notificationService.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notificationService.fetchNotifications(),
        child: notificationService.isLoading && notificationService.notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : notificationService.notifications.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _buildSectionHeader('Recent Updates'),
                      ...notificationService.notifications.map((n) => _NotificationItem(
                            notification: n,
                            icon: _getIconForNotification(n.mainText, n.description),
                            iconColor: _getIconColorForNotification(n.mainText),
                            timeStr: _formatTimeAgo(n.createdAt),
                            onRead: () => notificationService.markAsRead(n.id),
                          )),
                    ],
                  ),
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

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.bellOff, size: 64, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            Text(
              'No Notifications Yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'When DU releases new updates or seat allocations, you will see them here first!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends StatefulWidget {
  final DbNotification notification;
  final IconData icon;
  final Color iconColor;
  final String timeStr;
  final VoidCallback onRead;

  const _NotificationItem({
    required this.notification,
    required this.icon,
    required this.iconColor,
    required this.timeStr,
    required this.onRead,
  });

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
    final isUnread = n.isUnread;

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
                            color: widget.iconColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(widget.icon, color: widget.iconColor, size: 20),
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
                                  n.mainText,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                widget.timeStr,
                                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n.subText,
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
                    n.description,
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
