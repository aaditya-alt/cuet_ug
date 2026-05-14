import 'package:flutter/material.dart';
import '../models/college_model.dart';

class CompareProvider with ChangeNotifier {
  final List<CollegeModel> _compareList = [];

  List<CollegeModel> get compareList => _compareList;

  bool toggleCompare(CollegeModel college) {
    if (isInCompare(college.id)) {
      _compareList.removeWhere((c) => c.id == college.id);
      notifyListeners();
      return false;
    } else {
      if (_compareList.length >= 2) {
        // Automatically replace the second one or just ignore?
        // Let's ignore and let the user know (handled in UI)
        return false;
      }
      _compareList.add(college);
      notifyListeners();
      return true;
    }
  }

  bool isInCompare(String id) {
    return _compareList.any((c) => c.id == id);
  }

  void clearCompare() {
    _compareList.clear();
    notifyListeners();
  }

  int get count => _compareList.length;
}
