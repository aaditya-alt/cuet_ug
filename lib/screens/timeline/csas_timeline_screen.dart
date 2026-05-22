import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────
class TimelineEvent {
  final int id;
  final String title;
  final String date;
  final String time;
  final String description;
  final bool isCompleted;
  final bool isImportant;
  final String category;
  final String iconName;
  final String? linkUrl;
  final String? linkLabel;

  TimelineEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.description,
    required this.isCompleted,
    required this.isImportant,
    required this.category,
    required this.iconName,
    this.linkUrl,
    this.linkLabel,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> j) => TimelineEvent(
    id: j['id'] as int? ?? 0,
    title: j['title'] as String? ?? '',
    date: j['event_date'] as String? ?? '',
    time: j['event_time'] as String? ?? '',
    description: j['description'] as String? ?? '',
    isCompleted: j['is_completed'] as bool? ?? false,
    isImportant: j['is_important'] as bool? ?? false,
    category: j['category'] as String? ?? 'General',
    iconName: j['icon_name'] as String? ?? 'calendar',
    linkUrl: j['link_url'] as String?,
    linkLabel: j['link_label'] as String?,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ICON MAPPER
// ─────────────────────────────────────────────────────────────────────────────
IconData _iconFromName(String name) {
  switch (name) {
    case 'user-plus':
      return LucideIcons.userPlus;
    case 'credit-card':
      return LucideIcons.creditCard;
    case 'list-ordered':
      return LucideIcons.listOrdered;
    case 'lock':
      return LucideIcons.lock;
    case 'eye':
      return LucideIcons.eye;
    case 'award':
      return LucideIcons.award;
    case 'banknote':
      return LucideIcons.banknote;
    case 'refresh-cw':
      return LucideIcons.refreshCw;
    case 'flag':
      return LucideIcons.flag;
    case 'check-circle-2':
      return LucideIcons.checkCircle2;
    case 'file-text':
      return LucideIcons.fileText;
    case 'alert-triangle':
      return LucideIcons.alertTriangle;
    default:
      return LucideIcons.calendar;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY COLOR
// ─────────────────────────────────────────────────────────────────────────────
Color _categoryColor(String cat, BuildContext context) {
  switch (cat) {
    case 'Registration':
      return Colors.blue;
    case 'Choice Filling':
      return Colors.purple;
    case 'Allotment':
      return Colors.green;
    case 'Fees':
      return Colors.orange;
    default:
      return Theme.of(context).colorScheme.primary;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CsasTimelineScreen extends StatefulWidget {
  const CsasTimelineScreen({super.key});

  @override
  State<CsasTimelineScreen> createState() => _CsasTimelineScreenState();
}

class _CsasTimelineScreenState extends State<CsasTimelineScreen> {
  bool _isLoading = true;
  List<TimelineEvent> _events = [];
  String _filterCategory = 'All';

  final List<String> _categories = [
    'All',
    'Registration',
    'Choice Filling',
    'Allotment',
    'Fees',
    'General',
  ];

  // Fallback data if DB fails
  static const _fallback = [
    {
      'id': 1,
      'title': 'CSAS Registration Opens',
      'event_date': '28 May 2026',
      'event_time': '11:00 AM',
      'description':
          'Create your account on the DU Admission Portal and pay the registration fee.',
      'is_completed': true,
      'is_important': true,
      'category': 'Registration',
      'icon_name': 'user-plus',
      'link_url': 'https://admission.uod.ac.in',
      'link_label': 'Open Portal',
    },
    {
      'id': 2,
      'title': '1st Round Allotment',
      'event_date': '26 June 2026',
      'event_time': '10:00 AM',
      'description':
          'First round of seat allocation. Check and accept your allotment.',
      'is_completed': false,
      'is_important': true,
      'category': 'Allotment',
      'icon_name': 'award',
      'link_url': null,
      'link_label': null,
    },
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
          .eq('is_active', true)
          .order('sort_order');
      final list = res as List<dynamic>;
      setState(() {
        _events = (list.isNotEmpty ? list : _fallback)
            .map((j) => TimelineEvent.fromJson(j as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _events = _fallback.map((j) => TimelineEvent.fromJson(j)).toList();
        _isLoading = false;
      });
    }
  }

  List<TimelineEvent> get _filtered => _filterCategory == 'All'
      ? _events
      : _events.where((e) => e.category == _filterCategory).toList();

  int get _completedCount => _events.where((e) => e.isCompleted).length;
  int get _upcomingCount => _events.where((e) => !e.isCompleted).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0E14)
          : const Color(0xFFF4F6FF),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CSAS 2026',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Admission Timeline',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Progress bar
                        if (!_isLoading) ...[
                          Row(
                            children: [
                              Text(
                                '$_completedCount of ${_events.length} completed',
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$_upcomingCount upcoming',
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _events.isEmpty
                                  ? 0
                                  : _completedCount / _events.length,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation(
                                Colors.white,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              title: Text(
                'CSAS Timeline',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          // ── Category Filter ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF161C24) : Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final active = _filterCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filterCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? theme.colorScheme.primary
                                : (isDark
                                      ? Colors.white10
                                      : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // ── Timeline List ─────────────────────────────────────────────────
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _filtered.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No events in this category',
                      style: GoogleFonts.outfit(color: Colors.grey),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((ctx, i) {
                      final event = _filtered[i];
                      final isLast = i == _filtered.length - 1;
                      return _TimelineItem(
                        event: event,
                        isLast: isLast,
                        isDark: isDark,
                      );
                    }, childCount: _filtered.length),
                  ),
                ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIMELINE ITEM WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _TimelineItem extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;
  final bool isDark;

  const _TimelineItem({
    required this.event,
    required this.isLast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catColor = _categoryColor(event.category, context);
    final isCompleted = event.isCompleted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Line + Icon column ──────────────────────────────────────────
          SizedBox(
            width: 52,
            child: Column(
              children: [
                // Circle icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? catColor
                        : (isDark ? Colors.grey.shade800 : Colors.white),
                    border: Border.all(
                      color: isCompleted ? catColor : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: isCompleted
                        ? [
                            BoxShadow(
                              color: catColor.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _iconFromName(event.iconName),
                    size: 18,
                    color: isCompleted ? Colors.white : Colors.grey.shade400,
                  ),
                ),
                // Connecting line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [catColor, catColor.withOpacity(0.2)],
                              )
                            : null,
                        color: isCompleted ? null : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Card ──────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2233) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCompleted
                        ? catColor.withOpacity(0.3)
                        : (isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.grey.shade100),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isCompleted
                          ? catColor.withOpacity(0.06)
                          : Colors.black.withOpacity(0.02),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Row(
                        children: [
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              event.category,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: catColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Important badge
                          if (event.isImportant)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.alertCircle,
                                    size: 10,
                                    color: Colors.red.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Important',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Completed badge
                          if (isCompleted) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.check,
                                    size: 10,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Done',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Text(
                        event.title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isCompleted
                              ? catColor
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),

                    // Date + Time
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 13,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            event.date,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                            ),
                          ),
                          if (event.time.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(
                              LucideIcons.clock,
                              size: 13,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              event.time,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Description
                    if (event.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: Text(
                          event.description,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),

                    // Action button
                    if (event.linkUrl != null && event.linkLabel != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(event.linkUrl!);
                            if (await canLaunchUrl(uri)) {
                              launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          icon: Icon(
                            LucideIcons.externalLink,
                            size: 14,
                            color: catColor,
                          ),
                          label: Text(
                            event.linkLabel!,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: catColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: catColor.withOpacity(0.4)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
