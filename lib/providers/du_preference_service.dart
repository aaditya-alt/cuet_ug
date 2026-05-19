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

  DuPreferenceService() {
    loadLocalSheets();
  }

  // Save sheet (Supabase + Local Backup)
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
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    final newSheetMap = {
      'id': tempId,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'target_courses': targetCourses,
      'campus_preference': campusPreference,
      'priority_factor': priorityFactor,
      'sheet_data': sheetData,
      'created_at': DateTime.now().toIso8601String(),
    };

    bool savedToSupabase = false;

    // 1. Try to save to Supabase
    try {
      await _client.from('du_preference_sheets').insert({
        if (userId != null) 'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'target_courses': targetCourses,
        'campus_preference': campusPreference,
        'priority_factor': priorityFactor,
        'sheet_data': sheetData,
      });
      savedToSupabase = true;
      debugPrint('Successfully saved preference sheet to Supabase.');
    } catch (e) {
      debugPrint('Supabase save error (falling back to local): $e');
      // If table is missing, or network fails, we gracefully continue with local save
    }

    // 2. Save locally
    try {
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getStringList('du_preference_sheets') ?? [];
      localData.add(json.encode(newSheetMap));
      await prefs.setStringList('du_preference_sheets', localData);
      
      final newSheet = DuPreferenceSheet.fromJson(newSheetMap);
      _localSheets.insert(0, newSheet);
    } catch (e) {
      debugPrint('Local save error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return savedToSupabase;
  }

  // Load sheets from local storage
  Future<void> loadLocalSheets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> rawList = prefs.getStringList('du_preference_sheets') ?? [];
      _localSheets = rawList
          .map((item) => DuPreferenceSheet.fromJson(json.decode(item)))
          .toList()
          .reversed
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local sheets: $e');
    }
  }

  // Clear local sheets
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

  // Fetch all preference sheets for admin dashboard
  Future<List<DuPreferenceSheet>> fetchAllSheetsForAdmin() async {
    try {
      final response = await _client
          .from('du_preference_sheets')
          .select()
          .order('created_at', ascending: false);

      if (response != null && response is List) {
        return response
            .map((sheet) => DuPreferenceSheet.fromJson(sheet))
            .toList();
      }
    } catch (e) {
      debugPrint('Admin fetch sheets error: $e');
      // If the Supabase table doesn't exist, we'll return an empty list or let the caller catch it
      rethrow;
    }
    return [];
  }

  // Delete a preference sheet (Admin / User action)
  Future<void> deleteSheet(String id, {bool fromSupabaseOnly = false}) async {
    // 1. Delete from Supabase
    try {
      // Since tempId is used for local but Supabase generates uuid, we match by user_email/created_at if needed, or by primary UUID key.
      // For simplicity, if we pass the UUID, delete by it.
      await _client.from('du_preference_sheets').delete().eq('id', id);
    } catch (e) {
      debugPrint('Supabase delete error: $e');
    }

    if (fromSupabaseOnly) return;

    // 2. Delete locally
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> rawList = prefs.getStringList('du_preference_sheets') ?? [];
      final List<String> updatedList = [];

      for (var item in rawList) {
        final decoded = json.decode(item);
        if (decoded['id'] != id) {
          updatedList.add(item);
        }
      }

      await prefs.setStringList('du_preference_sheets', updatedList);
      _localSheets.removeWhere((sheet) => sheet.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Local delete error: $e');
    }
  }
}
