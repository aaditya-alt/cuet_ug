import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CsasTimelineScreen extends StatelessWidget {
  const CsasTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<TimelineEvent> events = [
      TimelineEvent(
        title: 'CSAS Registration Starts',
        date: '28 May 2026',
        time: '11:00 AM',
        description: 'Online registration at admission.uod.ac.in and deposition of Registration Fees.',
        isCompleted: true,
      ),
      TimelineEvent(
        title: 'Phase 1: Registration Ends',
        date: '15 June 2026',
        time: '11:59 PM',
        description: 'Last date to fill personal details and upload documents for Delhi University.',
        isCompleted: true,
      ),
      TimelineEvent(
        title: 'Phase 2: Choice Filling Starts',
        date: '17 June 2026',
        time: '11:00 AM',
        description: 'Preference filling for programs and colleges based on your CUET scores.',
        isCompleted: true,
      ),
      TimelineEvent(
        title: 'Mock Allotment List',
        date: '22 June 2026',
        time: '05:00 PM',
        description: 'Simulated list to help you understand your allotment chances.',
        isCompleted: false,
      ),
      TimelineEvent(
        title: '1st Round Allocation',
        date: '26 June 2026',
        time: '10:00 AM',
        description: 'First official allocation of seats across all DU colleges.',
        isCompleted: false,
      ),
      TimelineEvent(
        title: 'Physical Reporting & Fee',
        date: '27 - 30 June 2026',
        time: '04:00 PM',
        description: 'Reporting to allocated colleges for document verification and fee payment.',
        isCompleted: false,
      ),
      TimelineEvent(
        title: '2nd Round Allocation',
        date: '05 July 2026',
        time: '10:00 AM',
        description: 'Second round of seat allocation for remaining vacant seats.',
        isCompleted: false,
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'CSAS Timeline',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return _buildTimelineItem(context, events[index], index == 0, index == events.length - 1);
        },
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, TimelineEvent event, bool isFirst, bool isLast) {
    final theme = Theme.of(context);
    final accentColor = const Color(0xFF3498FF);

    return IntrinsicHeight(
      child: Row(
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: isFirst ? 20 : 30,
                  color: isFirst ? Colors.transparent : accentColor,
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: event.isCompleted ? accentColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor,
                      width: 2,
                    ),
                  ),
                  child: event.isCompleted
                      ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                      : null,
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : accentColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Event Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark 
                    ? const Color(0xFF161C24) 
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.calendar, size: 14, color: accentColor),
                        const SizedBox(width: 6),
                        Text(
                          '${event.date} • ${event.time}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimelineEvent {
  final String title;
  final String date;
  final String time;
  final String description;
  final bool isCompleted;

  TimelineEvent({
    required this.title,
    required this.date,
    required this.time,
    required this.description,
    required this.isCompleted,
  });
}
