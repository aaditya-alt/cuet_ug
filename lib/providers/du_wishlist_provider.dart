import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/du_models.dart';

/// Lightweight model stored in SharedPreferences for each wishlisted predictor college.
class DuWishlistItem {
  final String collegeName;
  final String? logoUrl;
  final String? campusType;
  final List<_WishlistProgram> programs;

  DuWishlistItem({
    required this.collegeName,
    this.logoUrl,
    this.campusType,
    this.programs = const [],
  });

  Map<String, dynamic> toJson() => {
        'college_name': collegeName,
        'logo_url': logoUrl,
        'campus_type': campusType,
        'programs': programs.map((p) => p.toJson()).toList(),
      };

  factory DuWishlistItem.fromJson(Map<String, dynamic> json) => DuWishlistItem(
        collegeName: json['college_name'] as String? ?? '',
        logoUrl: json['logo_url'] as String?,
        campusType: json['campus_type'] as String?,
        programs: (json['programs'] as List<dynamic>? ?? [])
            .map((e) => _WishlistProgram.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Construct a [DuWishlistItem] from a full [DuCollegeDetails] prediction result.
  factory DuWishlistItem.fromCollegeDetails(DuCollegeDetails college) =>
      DuWishlistItem(
        collegeName: college.collegeName,
        logoUrl: college.logoUrl,
        campusType: college.campusType,
        programs: college.programs
            .map((p) => _WishlistProgram(
                  name: p.programName,
                  degree: p.degree,
                  cutoff: p.cutoffScore.toInt(),
                  chance: p.chance,
                ))
            .toList(),
      );
}

class _WishlistProgram {
  final String name;
  final String degree;
  final int cutoff;
  final String chance;

  const _WishlistProgram({
    required this.name,
    required this.degree,
    required this.cutoff,
    required this.chance,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'degree': degree,
        'cutoff': cutoff,
        'chance': chance,
      };

  factory _WishlistProgram.fromJson(Map<String, dynamic> json) =>
      _WishlistProgram(
        name: json['name'] as String? ?? '',
        degree: json['degree'] as String? ?? '',
        cutoff: (json['cutoff'] as num?)?.toInt() ?? 0,
        chance: json['chance'] as String? ?? '',
      );
}

/// Provider that persists predictor-wishlisted colleges locally via SharedPreferences.
class DuWishlistProvider with ChangeNotifier {
  List<DuWishlistItem> _items = [];
  static const String _key = 'du_predictor_wishlist_v1';

  DuWishlistProvider() {
    _load();
  }

  List<DuWishlistItem> get items => List.unmodifiable(_items);

  bool isWishlisted(String collegeName) =>
      _items.any((i) => i.collegeName == collegeName);

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? [];
      _items = raw
          .map((s) {
            try {
              return DuWishlistItem.fromJson(
                  jsonDecode(s) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<DuWishlistItem>()
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('DuWishlistProvider load error: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _key,
        _items.map((i) => jsonEncode(i.toJson())).toList(),
      );
    } catch (e) {
      debugPrint('DuWishlistProvider save error: $e');
    }
  }

  void toggle(DuCollegeDetails college) {
    if (isWishlisted(college.collegeName)) {
      _items.removeWhere((i) => i.collegeName == college.collegeName);
    } else {
      _items.add(DuWishlistItem.fromCollegeDetails(college));
    }
    _save();
    notifyListeners();
  }

  void removeByName(String collegeName) {
    _items.removeWhere((i) => i.collegeName == collegeName);
    _save();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _save();
    notifyListeners();
  }
}
