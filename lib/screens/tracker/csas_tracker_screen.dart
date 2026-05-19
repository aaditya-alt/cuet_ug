import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/du_tracker_provider.dart';

class CsasTrackerScreen extends StatefulWidget {
  const CsasTrackerScreen({super.key});

  @override
  State<CsasTrackerScreen> createState() => _CsasTrackerScreenState();
}

class _CsasTrackerScreenState extends State<CsasTrackerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tracker = Provider.of<DuTrackerProvider>(context);

    // Dynamic phase details mapping
    final List<Map<String, dynamic>> phases = [
      {
        'id': 'phase1',
        'title': 'Phase 1: Registration',
        'subtitle': 'Personal profile details & document verification uploads.',
        'deadline': tracker.phase1Deadline,
        'color': const Color(0xFF6366F1),
      },
      {
        'id': 'phase2',
        'title': 'Phase 2: Preferences',
        'subtitle': 'Course and college selection alignment lists locking.',
        'deadline': tracker.phase2Deadline,
        'color': const Color(0xFF10B981),
      },
      {
        'id': 'phase3',
        'title': 'Phase 3: Seat Allocations',
        'subtitle': 'Rounds seat acceptances, fee payments, upgrades/freezes.',
        'deadline': tracker.phase3Deadline,
        'color': const Color(0xFFEC4899),
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(
          'CSAS Admissions Tracker',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Phase 1'),
            Tab(text: 'Phase 2'),
            Tab(text: 'Phase 3'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: phases.map((phase) {
          final phaseId = phase['id'] as String;
          final title = phase['title'] as String;
          final subtitle = phase['subtitle'] as String;
          final deadline = phase['deadline'] as DateTime;
          final phaseColor = phase['color'] as Color;

          final progress = tracker.getPhaseProgress(phaseId);
          final countdownStr = tracker.getCountdownString(deadline);
          final tasks = tracker.phaseTasks[phaseId] ?? [];
          final isCompleted = progress == 1.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phase Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: phaseColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: phaseColor.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: phaseColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCompleted ? LucideIcons.checkCircle2 : LucideIcons.activity,
                              color: phaseColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: phaseColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.grey : Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Countdown Deadline:',
                                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                countdownStr,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: countdownStr.contains('Closed') ? Colors.red : theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: phaseColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${(progress * 100).toInt()}% Done',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: phaseColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          color: phaseColor,
                          backgroundColor: phaseColor.withOpacity(0.15),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Interactive Checklist Label
                Text(
                  'Task Progress Checklist',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                if (isCompleted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.partyPopper, color: Colors.green, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phase Complete! 🎉',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Awesome! You are perfectly on track for this CSAS phase admissions cycle.',
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.green.shade800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Interactive Task Cards list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final key = 'csas_task_${phaseId}_${task.replaceAll(' ', '_')}';
                    final isChecked = tracker.taskStates[key] ?? false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 1,
                      child: InkWell(
                        onTap: () => tracker.toggleTask(phaseId, task),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isChecked ? phaseColor : Colors.transparent,
                                  border: Border.all(
                                    color: isChecked ? phaseColor : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: isChecked
                                    ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  task,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: isChecked ? FontWeight.w500 : FontWeight.normal,
                                    decoration: isChecked ? TextDecoration.lineThrough : null,
                                    color: isChecked ? Colors.grey : theme.textTheme.bodyLarge?.color,
                                  ),
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
          );
        }).toList(),
      ),
    );
  }
}
