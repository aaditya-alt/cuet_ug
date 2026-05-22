import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/du_tracker_provider.dart';

class CsasTrackerScreen extends StatefulWidget {
  const CsasTrackerScreen({super.key});

  @override
  State<CsasTrackerScreen> createState() => _CsasTrackerScreenState();
}

class _CsasTrackerScreenState extends State<CsasTrackerScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<String> _lastCategories = [];

  // ── Icon mapper ────────────────────────────────────────────────────────────
  IconData _iconFor(String name) {
    switch (name.toLowerCase()) {
      case 'calendar':
        return LucideIcons.calendar;
      case 'check':
        return LucideIcons.checkCircle2;
      case 'file':
        return LucideIcons.fileText;
      case 'upload':
        return LucideIcons.upload;
      case 'payment':
      case 'money':
        return LucideIcons.banknote;
      case 'lock':
        return LucideIcons.lock;
      case 'seat':
        return LucideIcons.mapPin;
      case 'document':
        return LucideIcons.clipboardList;
      case 'alert':
        return LucideIcons.alertCircle;
      case 'link':
        return LucideIcons.externalLink;
      case 'star':
        return LucideIcons.star;
      case 'info':
        return LucideIcons.info;
      case 'registration':
        return LucideIcons.userPlus;
      case 'preference':
        return LucideIcons.listOrdered;
      case 'allocation':
        return LucideIcons.award;
      default:
        return LucideIcons.calendar;
    }
  }

  // ── Category colour ────────────────────────────────────────────────────────
  Color _colorFor(String category) {
    switch (category.toLowerCase()) {
      case 'phase 1':
        return const Color(0xFF6366F1);
      case 'phase 2':
        return const Color(0xFF10B981);
      case 'phase 3':
        return const Color(0xFFEC4899);
      case 'general':
        return const Color(0xFFF59E0B);
      default:
        // deterministic colour from string hash
        final hue = (category.hashCode.abs() % 360).toDouble();
        return HSLColor.fromAHSL(1, hue, 0.6, 0.5).toColor();
    }
  }

  void _syncTabController(List<String> cats, TickerProvider vsync) {
    if (_tabController == null || cats.length != _lastCategories.length) {
      _tabController?.dispose();
      _tabController = TabController(length: cats.length, vsync: vsync);
      _lastCategories = List.of(cats);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // ── Launch URL ─────────────────────────────────────────────────────────────
  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tracker = Provider.of<DuTrackerProvider>(context);

    // ── Loading ──────────────────────────────────────────────────────────────
    if (tracker.isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0A0E14)
            : const Color(0xFFF8F9FF),
        appBar: AppBar(
          title: Text(
            'CSAS Tracker',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ── Error ────────────────────────────────────────────────────────────────
    if (tracker.loadError != null && tracker.allEvents.isEmpty) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0A0E14)
            : const Color(0xFFF8F9FF),
        appBar: AppBar(
          title: Text(
            'CSAS Tracker',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.wifiOff,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  tracker.loadError!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: tracker.fetchTimeline,
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final cats = tracker.categories;

    // ── Empty ────────────────────────────────────────────────────────────────
    if (cats.isEmpty) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0A0E14)
            : const Color(0xFFF8F9FF),
        appBar: AppBar(
          title: Text(
            'CSAS Tracker',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Text(
            'No timeline events found.',
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
        ),
      );
    }

    _syncTabController(cats, this);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0E14)
          : const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF161C24) : Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CSAS Admissions Tracker',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'DU 2026 Admission Cycle',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: theme.colorScheme.primary.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: tracker.fetchTimeline,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: cats.map((cat) {
            final progress = tracker.getPhaseProgress(cat);
            final pct = (progress * 100).toInt();
            return Tab(text: pct > 0 ? '$cat  $pct%' : cat);
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController!,
        children: cats.map((cat) {
          return _PhaseTab(
            category: cat,
            color: _colorFor(cat),
            tracker: tracker,
            isDark: isDark,
            theme: theme,
            iconFor: _iconFor,
            onLaunch: _launch,
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-phase tab content
// ─────────────────────────────────────────────────────────────────────────────
class _PhaseTab extends StatelessWidget {
  final String category;
  final Color color;
  final DuTrackerProvider tracker;
  final bool isDark;
  final ThemeData theme;
  final IconData Function(String) iconFor;
  final Future<void> Function(String) onLaunch;

  const _PhaseTab({
    required this.category,
    required this.color,
    required this.tracker,
    required this.isDark,
    required this.theme,
    required this.iconFor,
    required this.onLaunch,
  });

  DateTime _latestDateForCategory(String cat) {
    final evs = tracker.eventsByCategory[cat] ?? [];
    if (evs.isEmpty) return DateTime(2099);
    return evs.map((e) => e.dateTime).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final events = tracker.eventsByCategory[category] ?? [];
    final progress = tracker.getPhaseProgress(category);
    final isAllDone = progress == 1.0;

    // Deadline = latest event date in this category
    final deadline = _latestDateForCategory(category);
    final countdownStr = tracker.getCountdownString(deadline);
    final isClosed = countdownStr.contains('Closed');

    return RefreshIndicator(
      onRefresh: tracker.fetchTimeline,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Phase summary card ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withOpacity(0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAllDone
                              ? LucideIcons.checkCircle2
                              : LucideIcons.activity,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: color,
                          ),
                        ),
                      ),
                      // Event count badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '${events.length} events',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Countdown row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phase Deadline',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            countdownStr,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isClosed
                                  ? Colors.red
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${(progress * 100).toInt()}% Done',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      color: color,
                      backgroundColor: color.withOpacity(0.14),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            // ── All done banner ─────────────────────────────────────────────
            if (isAllDone) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.partyPopper,
                      color: Colors.green,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All tasks marked! You\'re on track 🎉',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            Text(
              'Timeline Events',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // ── Events list ─────────────────────────────────────────────────
            ...events.map(
              (event) => _EventCard(
                event: event,
                color: color,
                isDark: isDark,
                theme: theme,
                tracker: tracker,
                iconFor: iconFor,
                onLaunch: onLaunch,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual event card
// ─────────────────────────────────────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  final CsasTimelineEvent event;
  final Color color;
  final bool isDark;
  final ThemeData theme;
  final DuTrackerProvider tracker;
  final IconData Function(String) iconFor;
  final Future<void> Function(String) onLaunch;

  const _EventCard({
    required this.event,
    required this.color,
    required this.isDark,
    required this.theme,
    required this.tracker,
    required this.iconFor,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    final isChecked = tracker.isTaskChecked(event.id);
    final countdown = tracker.getEventCountdown(event);
    final isClosed = countdown.contains('Closed');
    final isPast = event.dateTime.isBefore(DateTime.now());

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isChecked
            ? color.withOpacity(0.05)
            : (isDark ? const Color(0xFF1A2233) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: event.isImportant
              ? color.withOpacity(0.5)
              : (isChecked
                    ? color.withOpacity(0.3)
                    : (isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.grey.shade200)),
          width: event.isImportant ? 1.5 : 1,
        ),
        boxShadow: event.isImportant
            ? [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => tracker.toggleTask(event.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Checkbox ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isChecked ? color : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isChecked ? color : Colors.grey.shade400,
                        width: 1.8,
                      ),
                    ),
                    child: isChecked
                        ? const Icon(
                            LucideIcons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),

                // ── Content ─────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        children: [
                          Icon(
                            iconFor(event.iconName),
                            size: 14,
                            color: isChecked ? Colors.grey : color,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              event.title,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                decoration: isChecked
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isChecked
                                    ? Colors.grey
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                          ),
                          // Important badge
                          if (event.isImportant)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'Important',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Description
                      if (event.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 5),
                        Text(
                          event.description!,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey,
                            height: 1.4,
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Date + countdown row
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          _Tag(
                            icon: LucideIcons.calendar,
                            label: event.eventTime != null
                                ? '${event.eventDate}  ${event.eventTime}'
                                : event.eventDate,
                            color: isPast
                                ? Colors.grey
                                : theme.colorScheme.primary,
                          ),
                          _Tag(
                            icon: isClosed
                                ? LucideIcons.checkCircle
                                : LucideIcons.clock,
                            label: countdown,
                            color: isClosed
                                ? Colors.green.shade600
                                : (isPast
                                      ? Colors.red.shade400
                                      : Colors.amber.shade700),
                          ),
                        ],
                      ),

                      // Link button
                      if (event.linkUrl?.isNotEmpty == true) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => onLaunch(event.linkUrl!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: color.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.externalLink,
                                  size: 12,
                                  color: color,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  event.linkLabel?.isNotEmpty == true
                                      ? event.linkLabel!
                                      : 'Open Link',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tiny tag row widget
// ─────────────────────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Tag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
