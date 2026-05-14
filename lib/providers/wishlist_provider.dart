import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/college_model.dart';
import '../data/mock_data.dart';

class WishlistProvider with ChangeNotifier {
  List<CollegeModel> _wishlist = [];
  static const String _key = 'wishlist_ids';

  WishlistProvider() {
    _loadFromPrefs();
  }

  List<CollegeModel> get wishlist => _wishlist;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> ids = prefs.getStringList(_key) ?? [];
    
    // Map IDs back to models from MockData
    _wishlist = ids.map((id) {
      return MockData.colleges.firstWhere(
        (c) => c.id == id,
        orElse: () => MockData.colleges.first, // Fallback if ID not found
      );
    }).toList();
    
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = _wishlist.map((c) => c.id).toList();
    await prefs.setStringList(_key, ids);
  }

  void toggleWishlist(CollegeModel college) {
    if (isInWishlist(college.id)) {
      _wishlist.removeWhere((c) => c.id == college.id);
    } else {
      _wishlist.add(college);
    }
    _saveToPrefs();
    notifyListeners();
  }

  bool isInWishlist(String id) {
    return _wishlist.any((c) => c.id == id);
  }

  void reorderWishlist(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final CollegeModel item = _wishlist.removeAt(oldIndex);
    _wishlist.insert(newIndex, item);
    _saveToPrefs();
    notifyListeners();
  }

  void clearWishlist() {
    _wishlist.clear();
    _saveToPrefs();
    notifyListeners();
  }
}
