import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/du_models.dart';

class DuPreferenceService extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  List<DuPreferenceSheet> _localSheets = [];
  bool _isLoading = false;

  List<DuPreferenceSheet> get localSheets => _localSheets;
  bool get isLoading => _isLoading;

  // Sheets that were saved locally while offline and haven't been synced yet
  List<DuPreferenceSheet> get unsyncedSheets =>
      _localSheets.where((s) => s.syncedToServer == false).toList();

  DuPreferenceService() {
    loadLocalSheets();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SAVE
  // ─────────────────────────────────────────────────────────────────────────

  /// Saves a preference sheet. Tries Supabase first; always saves locally.
  /// Returns true if Supabase write succeeded.
  Future<bool> savePreferenceSheet({
    required String userName,
    required String userEmail,
    required List<String> targetCourses,
    required String campusPreference,
    required String priorityFactor,
    required List<Map<String, dynamic>> sheetData,
  }) async {
    _isLoading = true;
    notifyListeners();

    final userId = _client.auth.currentUser?.id;
    final now = DateTime.now().toIso8601String();

    // We use a local-only temp ID until we get the real UUID from Supabase
    final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    bool savedToSupabase = false;
    String persistedId = tempId;

    // ── 1. Try Supabase ─────────────────────────────────────────────────────
    try {
      final inserted = await _client
          .from('du_preference_sheets')
          .insert({
            if (userId != null) 'user_id': userId,
            'user_name': userName,
            'user_email': userEmail,
            'target_courses': targetCourses,
            'campus_preference': campusPreference,
            'priority_factor': priorityFactor,
            'sheet_data': sheetData,
            'created_at': now,
          })
          .select('id')
          .single();

      // Use the real UUID returned by Supabase
      persistedId = inserted['id'] as String;
      savedToSupabase = true;
      debugPrint('Preference sheet saved to Supabase. id=$persistedId');
    } catch (e) {
      debugPrint('Supabase save failed (local fallback): $e');
    }

    // ── 2. Always save locally ──────────────────────────────────────────────
    try {
      final localMap = {
        'id': persistedId,
        'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'target_courses': targetCourses,
        'campus_preference': campusPreference,
        'priority_factor': priorityFactor,
        'sheet_data': sheetData,
        'created_at': now,
        // Custom local flag — not a Supabase column
        '_synced': savedToSupabase,
      };

      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList('du_preference_sheets') ?? [];
      rawList.insert(0, json.encode(localMap));
      await prefs.setStringList('du_preference_sheets', rawList);

      _localSheets.insert(0, DuPreferenceSheet.fromJson(localMap));
    } catch (e) {
      debugPrint('Local save failed: $e');
    }

    _isLoading = false;
    notifyListeners();
    return savedToSupabase;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOAD
  // ─────────────────────────────────────────────────────────────────────────

  /// Loads sheets from local SharedPreferences cache.
  Future<void> loadLocalSheets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList('du_preference_sheets') ?? [];
      _localSheets = rawList
          .map((s) => DuPreferenceSheet.fromJson(json.decode(s)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local sheets: $e');
    }
  }

  /// Fetches the current user's own sheets from Supabase.
  /// Merges them into _localSheets so the UI is always up to date.
  Future<List<DuPreferenceSheet>> fetchUserSheets() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return _localSheets;

    try {
      final response = await _client
          .from('du_preference_sheets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final serverSheets = (response as List)
          .map((s) => DuPreferenceSheet.fromJson(s))
          .toList();

      // Merge: replace local cache with server truth, keep unsynced locals
      final unsynced = unsyncedSheets;
      _localSheets = [...unsynced, ...serverSheets];
      await _persistLocalCache();
      notifyListeners();
      return _localSheets;
    } catch (e) {
      debugPrint('fetchUserSheets error: $e');
      return _localSheets; // return cached data on failure
    }
  }

  /// Fetches ALL sheets (admin only). Does NOT merge into _localSheets.
  Future<List<DuPreferenceSheet>> fetchAllSheetsForAdmin() async {
    try {
      final response = await _client
          .from('du_preference_sheets')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((s) => DuPreferenceSheet.fromJson(s))
          .toList();
    } catch (e) {
      debugPrint('fetchAllSheetsForAdmin error: $e');
      return []; // never rethrow — let the UI handle empty gracefully
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SYNC
  // ─────────────────────────────────────────────────────────────────────────

  /// Attempts to push locally-saved (unsynced) sheets to Supabase.
  /// Call this when the app regains connectivity.
  Future<void> syncLocalToSupabase() async {
    final pending = unsyncedSheets;
    if (pending.isEmpty) return;

    debugPrint('Syncing ${pending.length} unsynced sheets…');

    for (final sheet in pending) {
      try {
        final inserted = await _client
            .from('du_preference_sheets')
            .insert({
              'user_name': sheet.userName,
              'user_email': sheet.userEmail,
              'target_courses': sheet.targetCourses,
              'campus_preference': sheet.campusPreference,
              'priority_factor': sheet.priorityFactor,
              'sheet_data': sheet.sheetData,
              'created_at': sheet.createdAt?.toIso8601String(),
            })
            .select('id')
            .single();

        final realId = inserted['id'] as String;

        // Update local entry: swap temp ID for real UUID, mark synced
        final idx = _localSheets.indexWhere((s) => s.id == sheet.id);
        if (idx != -1) {
          _localSheets[idx] = _localSheets[idx].copyWith(
            id: realId,
            syncedToServer: true,
          );
        }

        debugPrint('Synced sheet ${sheet.id} → $realId');
      } catch (e) {
        debugPrint('Failed to sync sheet ${sheet.id}: $e');
      }
    }

    await _persistLocalCache();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────────────────────

  /// Deletes a sheet. If the ID is a real Supabase UUID (not temp),
  /// it's deleted server-side too.
  Future<void> deleteSheet(
    String id, {
    bool serverOnly = false,
    required bool fromSupabaseOnly,
  }) async {
    // ── Server delete (only if it's not a temp local ID) ──────────────────
    if (!id.startsWith('local_')) {
      try {
        await _client.from('du_preference_sheets').delete().eq('id', id);
        debugPrint('Deleted sheet $id from Supabase.');
      } catch (e) {
        debugPrint('Supabase delete error for $id: $e');
      }
    }

    if (serverOnly) return;

    // ── Local delete ───────────────────────────────────────────────────────
    _localSheets.removeWhere((s) => s.id == id);
    await _persistLocalCache();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CLEAR
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> clearLocalSheets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('du_preference_sheets');
      _localSheets.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing local sheets: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Writes the current _localSheets list back to SharedPreferences.
  Future<void> _persistLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = _localSheets.map((s) => json.encode(s.toJson())).toList();
      await prefs.setStringList('du_preference_sheets', encoded);
    } catch (e) {
      debugPrint('Error persisting local cache: $e');
    }
  }
}
