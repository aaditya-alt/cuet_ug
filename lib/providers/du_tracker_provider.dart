import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────
class CsasTimelineEvent {
  final int id;
  final String title;
  final String eventDate; // stored as text e.g. "2026-06-15"
  final String? eventTime; // e.g. "23:59"
  final String? description;
  final bool isCompleted;
  final int sortOrder;
  final String category; // "Phase 1" / "Phase 2" / "Phase 3" / "General"
  final String iconName;
  final bool isImportant;
  final String? linkUrl;
  final String? linkLabel;
  final bool isActive;

  CsasTimelineEvent({
    required this.id,
    required this.title,
    required this.eventDate,
    this.eventTime,
    this.description,
    required this.isCompleted,
    required this.sortOrder,
    required this.category,
    required this.iconName,
    required this.isImportant,
    this.linkUrl,
    this.linkLabel,
    required this.isActive,
  });

  factory CsasTimelineEvent.fromJson(Map<String, dynamic> j) {
    return CsasTimelineEvent(
      id: j['id'] as int,
      title: j['title'] as String? ?? '',
      eventDate: j['event_date'] as String? ?? '',
      eventTime: j['event_time'] as String?,
      description: j['description'] as String?,
      isCompleted: j['is_completed'] as bool? ?? false,
      sortOrder: j['sort_order'] as int? ?? 0,
      category: j['category'] as String? ?? 'General',
      iconName: j['icon_name'] as String? ?? 'calendar',
      isImportant: j['is_important'] as bool? ?? false,
      linkUrl: j['link_url'] as String?,
      linkLabel: j['link_label'] as String?,
      isActive: j['is_active'] as bool? ?? true,
    );
  }

  /// Parses event_date + event_time into a DateTime.
  /// Falls back gracefully if format is unexpected.
  DateTime get dateTime {
    try {
      final datePart = eventDate.trim();
      final timePart = (eventTime?.trim().isNotEmpty == true)
          ? eventTime!.trim()
          : '23:59:59';
      return DateTime.parse('$datePart $timePart');
    } catch (_) {
      return DateTime(2099); // push unknown dates to the end
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────────────────
class DuTrackerProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final SupabaseClient _client = Supabase.instance.client;

  Timer? _countdownTimer;

  // All active events from csas_timeline
  List<CsasTimelineEvent> _events = [];
  bool isLoading = true;
  String? loadError;

  // Per-task local checkbox states (keyed by event id)
  final Map<String, bool> _taskStates = {};

  DuTrackerProvider(this._prefs) {
    _loadLocalTaskStates();
    fetchTimeline();
    _startCountdownTicker();
  }

  // ── Public getters ─────────────────────────────────────────────────────────

  List<CsasTimelineEvent> get allEvents => _events;
  Map<String, bool> get taskStates => _taskStates;

  /// Events grouped by category, only active ones, sorted by sort_order.
  Map<String, List<CsasTimelineEvent>> get eventsByCategory {
    final Map<String, List<CsasTimelineEvent>> map = {};
    for (final e in _events.where((e) => e.isActive)) {
      map.putIfAbsent(e.category, () => []).add(e);
    }
    // Sort each category's list by sort_order
    for (final list in map.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return map;
  }

  /// Sorted list of unique categories in sort_order sequence.
  List<String> get categories {
    final seen = <String>{};
    return _events
        .where((e) => e.isActive)
        .map((e) => e.category)
        .where(seen.add)
        .toList();
  }

  // ── Phase deadline helpers ─────────────────────────────────────────────────
  // These find the latest event_date in each Phase category as the deadline.

  DateTime _latestDateForCategory(String cat) {
    final evs = eventsByCategory[cat] ?? [];
    if (evs.isEmpty) return DateTime(2099);
    return evs.map((e) => e.dateTime).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  DateTime get phase1Deadline => _latestDateForCategory('Phase 1');
  DateTime get phase2Deadline => _latestDateForCategory('Phase 2');
  DateTime get phase3Deadline => _latestDateForCategory('Phase 3');

  // ── Checklist helpers ──────────────────────────────────────────────────────

  String _taskKey(int eventId) => 'csas_task_event_$eventId';

  void _loadLocalTaskStates() {
    final keys = _prefs.getKeys();
    for (final k in keys) {
      if (k.startsWith('csas_task_event_')) {
        _taskStates[k] = _prefs.getBool(k) ?? false;
      }
    }
  }

  Future<void> toggleTask(int eventId) async {
    final key = _taskKey(eventId);
    final current = _taskStates[key] ?? false;
    _taskStates[key] = !current;
    await _prefs.setBool(key, !current);
    notifyListeners();
  }

  bool isTaskChecked(int eventId) => _taskStates[_taskKey(eventId)] ?? false;

  /// Progress 0.0–1.0 for a given category based on local checkbox states.
  double getPhaseProgress(String category) {
    final evs = (eventsByCategory[category] ?? []);
    if (evs.isEmpty) return 0.0;
    final checked = evs.where((e) => isTaskChecked(e.id)).length;
    return checked / evs.length;
  }

  // ── Data fetch ─────────────────────────────────────────────────────────────

  Future<void> fetchTimeline() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final res = await _client
          .from('csas_timeline')
          .select()
          .eq('is_active', true)
          .order('sort_order')
          .order('event_date');

      _events = (res as List)
          .map((r) => CsasTimelineEvent.fromJson(r))
          .toList();
    } catch (e) {
      loadError = 'Could not load timeline: $e';
      debugPrint('fetchTimeline error: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  // ── Countdown ──────────────────────────────────────────────────────────────

  void _startCountdownTicker() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  String getCountdownString(DateTime deadline) {
    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative) return 'Completed / Closed';
    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    if (d > 0) return '$d d $h hrs left';
    if (h > 0) return '$h hrs $m mins left';
    return '$m mins $s secs left';
  }

  /// Countdown to a specific event's own deadline.
  String getEventCountdown(CsasTimelineEvent event) =>
      getCountdownString(event.dateTime);

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
