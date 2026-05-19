import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DuTrackerProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final SupabaseClient _client = Supabase.instance.client;

  // Active ticking timer for real-time countdown updates
  Timer? _countdownTimer;

  // Checklist items by Phase
  final Map<String, List<String>> _phaseTasks = {
    'phase1': [
      'Fill personal & category details accurately',
      'Upload Class XII Marksheet (Digilocker verified)',
      'Confirm Board subject maps to CUET subjects',
      'Pay CSAS Phase 1 registration fee online',
    ],
    'phase2': [
      'Verify programmatic eligibility scoring metrics',
      'Generate optimized college-course preference sheet',
      'Select and rank a minimum of 30 colleges',
      'Lock preference priorities list before deadline',
    ],
    'phase3': [
      'Check Round 1 allocation notifications',
      'Accept allocated seat (must complete in 24 hours)',
      'Verify document status with the college admin',
      'Complete online college admission fee payment',
    ],
  };

  // User persistent checklist marked states (task_key -> checked)
  final Map<String, bool> _taskStates = {};

  // Phase milestones target deadlines
  DateTime _phase1Deadline = DateTime(2026, 6, 15, 23, 59, 59);
  DateTime _phase2Deadline = DateTime(2026, 7, 5, 23, 59, 59);
  DateTime _phase3Deadline = DateTime(2026, 7, 20, 23, 59, 59);

  DuTrackerProvider(this._prefs) {
    _loadChecklistStates();
    _fetchDeadlinesFromDb();
    _startCountdownTicker();
  }

  Map<String, List<String>> get phaseTasks => _phaseTasks;
  Map<String, bool> get taskStates => _taskStates;

  DateTime get phase1Deadline => _phase1Deadline;
  DateTime get phase2Deadline => _phase2Deadline;
  DateTime get phase3Deadline => _phase3Deadline;

  // Load checklist checkmarks from disk cache
  void _loadChecklistStates() {
    for (final phase in _phaseTasks.keys) {
      final tasks = _phaseTasks[phase]!;
      for (final task in tasks) {
        final key = _getTaskKey(phase, task);
        _taskStates[key] = _prefs.getBool(key) ?? false;
      }
    }
    notifyListeners();
  }

  // Generate unique storage identifier
  String _getTaskKey(String phase, String task) {
    return 'csas_task_${phase}_${task.replaceAll(' ', '_')}';
  }

  // Toggle check state persistently
  Future<void> toggleTask(String phase, String task) async {
    final key = _getTaskKey(phase, task);
    final currentState = _taskStates[key] ?? false;
    final newState = !currentState;
    
    _taskStates[key] = newState;
    await _prefs.setBool(key, newState);
    notifyListeners();
  }

  // Calculate percentage completion of a phase
  double getPhaseProgress(String phase) {
    final tasks = _phaseTasks[phase] ?? [];
    if (tasks.isEmpty) return 0.0;
    
    int checkedCount = 0;
    for (final task in tasks) {
      final key = _getTaskKey(phase, task);
      if (_taskStates[key] == true) {
        checkedCount++;
      }
    }
    return checkedCount / tasks.length;
  }

  // Pull timeline updates dynamically from DB
  Future<void> _fetchDeadlinesFromDb() async {
    try {
      final response = await _client
          .from('du_timeline_deadlines')
          .select()
          .maybeSingle();

      if (response != null && response is Map) {
        if (response['phase1_deadline'] != null) {
          _phase1Deadline = DateTime.parse(response['phase1_deadline'].toString());
        }
        if (response['phase2_deadline'] != null) {
          _phase2Deadline = DateTime.parse(response['phase2_deadline'].toString());
        }
        if (response['phase3_deadline'] != null) {
          _phase3Deadline = DateTime.parse(response['phase3_deadline'].toString());
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Dynamic deadlines load error (using default schedules): $e');
    }
  }

  // Set deadlines locally and trigger database backup (called by Admin Dashboard!)
  Future<bool> updateDeadlines({
    required DateTime p1,
    required DateTime p2,
    required DateTime p3,
  }) async {
    _phase1Deadline = p1;
    _phase2Deadline = p2;
    _phase3Deadline = p3;
    notifyListeners();

    try {
      // Upsert to timeline deadlines configuration table
      await _client.from('du_timeline_deadlines').upsert({
        'id': 'singleton_timeline',
        'phase1_deadline': p1.toIso8601String(),
        'phase2_deadline': p2.toIso8601String(),
        'phase3_deadline': p3.toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Failed to save configuration deadlines to Supabase (locally applied): $e');
      return false;
    }
  }

  // Dynamic ticking calculations
  void _startCountdownTicker() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      notifyListeners();
    });
  }

  // Formatted countdown strings
  String getCountdownString(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Completed / Closed';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    if (days > 0) {
      return '$days d, $hours hrs left';
    } else if (hours > 0) {
      return '$hours hrs, $minutes mins left';
    } else {
      return '$minutes mins, $seconds secs left';
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
