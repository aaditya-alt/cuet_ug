import 'package:flutter/material.dart';

class FilterProvider with ChangeNotifier {
  List<String> _selectedCampuses = [];
  List<String> _selectedTypes = [];
  String? _selectedCourse;
  String _searchQuery = '';

  List<String> get selectedCampuses => _selectedCampuses;
  List<String> get selectedTypes => _selectedTypes;
  String? get selectedCourse => _selectedCourse;
  String get searchQuery => _searchQuery;

  void toggleCampus(String campus) {
    if (_selectedCampuses.contains(campus)) {
      _selectedCampuses.remove(campus);
    } else {
      _selectedCampuses.add(campus);
    }
    notifyListeners();
  }

  void toggleType(String type) {
    if (_selectedTypes.contains(type)) {
      _selectedTypes.remove(type);
    } else {
      _selectedTypes.add(type);
    }
    notifyListeners();
  }

  void setCourse(String? course) {
    _selectedCourse = course;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void resetFilters() {
    _selectedCampuses = [];
    _selectedTypes = [];
    _selectedCourse = null;
    _searchQuery = '';
    notifyListeners();
  }

  bool get hasFilters => 
      _selectedCampuses.isNotEmpty || 
      _selectedTypes.isNotEmpty || 
      _selectedCourse != null || 
      _searchQuery.isNotEmpty;
}
