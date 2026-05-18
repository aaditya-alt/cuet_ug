import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CsasTimelineScreen extends StatefulWidget {
  const CsasTimelineScreen({super.key});

  @override
  State<CsasTimelineScreen> createState() => _CsasTimelineScreenState();
}

class _CsasTimelineScreenState extends State<CsasTimelineScreen> {
  bool _isLoading = true;
  List<TimelineEvent> _events = [];

  final List<TimelineEvent> _fallbackEvents = [
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
  ];

  @override
  void initState() {
    super.initState();
    _fetchTimeline();
  }

  Future<void> _fetchTimeline() async {
    try {
      final res = await Supabase.instance.client
          .from('csas_timeline')
          .select()
          .order('sort_order', ascending: true);
      
      final data = res as List<dynamic>;
      if (data.isNotEmpty) {
        setState(() {
          _events = data.map((json) => TimelineEvent(
            title: json['title'] ?? '',
            date: json['event_date'] ?? '',
            time: json['event_time'] ?? '',
            description: json['description'] ?? '',
            isCompleted: json['is_completed'] ?? false,
          )).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _events = _fallbackEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching timeline: $e');
      setState(() {
        _events = _fallbackEvents;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CSAS Timeline 2026'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          final isLast = index == _events.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line and icon
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: event.isCompleted
                          ? theme.colorScheme.primary
                          : (isDark ? Colors.grey.shade800 : Colors.white),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: event.isCompleted
                            ? theme.colorScheme.primary
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      event.isCompleted
                          ? LucideIcons.check
                          : LucideIcons.circleDot,
                      size: 16,
                      color: event.isCompleted
                          ? Colors.white
                          : Colors.grey.shade400,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 100, // Fixed height for visual consistency
                      color: event.isCompleted
                          ? theme.colorScheme.primary.withOpacity(0.5)
                          : Colors.grey.shade200,
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Content Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: event.isCompleted
                            ? theme.colorScheme.primary.withOpacity(0.3)
                            : Colors.transparent,
                      ),
                      boxShadow: [
                        if (event.isCompleted)
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        else
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: event.isCompleted
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 14,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.date,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              LucideIcons.clock,
                              size: 14,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.time,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          event.description,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
