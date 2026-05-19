import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'chat_room_screen.dart';

class CommunityHubScreen extends StatelessWidget {
  const CommunityHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Map<String, dynamic>> channels = [
      {
        'id': 'general',
        'title': 'General Lounge',
        'desc':
            'CUET prep tips, document mapping, timeline milestones, and overall DU assistance.',
        'icon': LucideIcons.messageSquare,
        'gradient': [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
        'members': '4.2k members',
        'unread': 'Active now',
      },
      {
        'id': 'commerce',
        'title': 'Commerce & BMS',
        'desc':
            'Targetting B.Com Hons, Economics Hons, BMS, or BBA? Share mock scores & college cutoffs here.',
        'icon': LucideIcons.banknote,
        'gradient': [const Color(0xFF10B981), const Color(0xFF059669)],
        'members': '2.8k members',
        'unread': 'Highly Active',
      },
      {
        'id': 'science',
        'title': 'Tech & Sciences',
        'desc':
            'Physics, Chemistry, Maths, CS, and B.Tech aspirants discussing labs, faculty, and cutoffs.',
        'icon': LucideIcons.flaskRound,
        'gradient': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        'members': '1.9k members',
        'unread': 'Active now',
      },
      {
        'id': 'humanities',
        'title': 'Humanities & Arts',
        'desc':
            'History, Pol Sci, English Hons, and journalism. Discuss core subjects and campus preferences.',
        'icon': LucideIcons.palette,
        'gradient': [const Color(0xFFEC4899), const Color(0xFFDB2777)],
        'members': '2.1k members',
        'unread': 'Active now',
      },
    ];

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0E14)
          : const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(
          'DUVerse Community Hub',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.users,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join the Aspirants Community',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Interact in real-time with fellow DU aspirants, share updates, and clear your doubts instantly.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: isDark ? Colors.grey : Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text(
              'Select a Discussion Forum',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Channels List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRoomScreen(
                            channelId: channel['id'],
                            channelTitle: channel['title'],
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: channel['gradient'],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  channel['icon'],
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      channel['title'],
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          channel['members'],
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 4,
                                          height: 4,
                                          decoration: const BoxDecoration(
                                            color: Colors.grey,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          channel['unread'],
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                LucideIcons.chevronRight,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            channel['desc'],
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
