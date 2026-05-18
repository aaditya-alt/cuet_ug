import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppSettingsProvider with ChangeNotifier {
  bool _premiumEnabled = false;
  bool _isLoading = false;

  bool get premiumEnabled => _premiumEnabled;
  bool get isLoading => _isLoading;

  AppSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // 1) Load from local cache first to render instantly
    final prefs = await SharedPreferences.getInstance();
    _premiumEnabled = prefs.getBool('premium_enabled') ?? false;
    notifyListeners();

    // 2) Try to fetch latest value from Supabase
    try {
      final res = await Supabase.instance.client
          .from('app_settings')
          .select()
          .eq('key', 'premium_enabled')
          .maybeSingle();

      if (res != null) {
        final val = res['value'] == 'true' || res['value'] == true;
        if (_premiumEnabled != val) {
          _premiumEnabled = val;
          await prefs.setBool('premium_enabled', val);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch premium_enabled from Supabase app_settings: $e');
    }
  }

  Future<void> togglePremiumEnabled(bool val) async {
    _premiumEnabled = val;
    notifyListeners();

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('premium_enabled', val);

    // Save to Supabase (upsert or update)
    try {
      await Supabase.instance.client.from('app_settings').upsert({
        'key': 'premium_enabled',
        'value': val ? 'true' : 'false',
      });
    } catch (e) {
      debugPrint('Supabase app_settings upsert error: $e');
      // No crash, just proceed with local settings
    }
  }
}
