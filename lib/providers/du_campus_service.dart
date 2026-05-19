import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CampusGuideItem {
  final String id;
  final String collegeName;
  final String campusType; // 'north', 'south', 'off'
  final String nearestMetro;
  final String metroLine; // 'Yellow', 'Pink', 'Violet', 'Blue'
  final int walkingDistanceMins;
  final int eRickshawFare;
  final int avgPgRent; // Average monthly rent
  final double safetyIndex; // rating out of 5
  final String description;

  CampusGuideItem({
    required this.id,
    required this.collegeName,
    required this.campusType,
    required this.nearestMetro,
    required this.metroLine,
    required this.walkingDistanceMins,
    required this.eRickshawFare,
    required this.avgPgRent,
    required this.safetyIndex,
    required this.description,
  });

  factory CampusGuideItem.fromJson(Map<String, dynamic> json) {
    return CampusGuideItem(
      id: json['id'] ?? '',
      collegeName: json['college_name'] ?? '',
      campusType: json['campus_type'] ?? 'north',
      nearestMetro: json['nearest_metro'] ?? '',
      metroLine: json['metro_line'] ?? 'Yellow',
      walkingDistanceMins: json['walking_distance_mins'] ?? 10,
      eRickshawFare: json['e_rickshaw_fare'] ?? 10,
      avgPgRent: json['avg_pg_rent'] ?? 8000,
      safetyIndex: (json['safety_index'] ?? 4.0).toDouble(),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'college_name': collegeName,
      'campus_type': campusType,
      'nearest_metro': nearestMetro,
      'metro_line': metroLine,
      'walking_distance_mins': walkingDistanceMins,
      'e_rickshaw_fare': eRickshawFare,
      'avg_pg_rent': avgPgRent,
      'safety_index': safetyIndex,
      'description': description,
    };
  }
}

class DuCampusService extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  List<CampusGuideItem> _guides = [];
  bool _isLoading = false;

  List<CampusGuideItem> get guides => _guides;
  bool get isLoading => _isLoading;

  // Preloaded high-value seeds for offline or dynamic fallback
  final List<CampusGuideItem> _seededGuides = [
    CampusGuideItem(
      id: 'srcc_guide',
      collegeName: 'Shri Ram College of Commerce (SRCC)',
      campusType: 'north',
      nearestMetro: 'Vishwa Vidyalaya',
      metroLine: 'Yellow',
      walkingDistanceMins: 12,
      eRickshawFare: 10,
      avgPgRent: 12000,
      safetyIndex: 4.8,
      description: 'SRCC is situated in North Campus. The closest station is Vishwa Vidyalaya. Students usually prefer walking through the campus or taking a shared e-rickshaw for ₹10. Accommodation is popular in Kamla Nagar, Vijay Nagar, and Hudson Lane.',
    ),
    CampusGuideItem(
      id: 'hindu_guide',
      collegeName: 'Hindu College',
      campusType: 'north',
      nearestMetro: 'Vishwa Vidyalaya',
      metroLine: 'Yellow',
      walkingDistanceMins: 10,
      eRickshawFare: 10,
      avgPgRent: 11000,
      safetyIndex: 4.7,
      description: 'Located in heart of North Campus. Extremely accessible. E-rickshaws are lined up right outside Vishwa Vidyalaya station gates. Kamla Nagar is the major student shopping & PG hub nearby.',
    ),
    CampusGuideItem(
      id: 'hansraj_guide',
      collegeName: 'Hansraj College',
      campusType: 'north',
      nearestMetro: 'Vishwa Vidyalaya',
      metroLine: 'Yellow',
      walkingDistanceMins: 14,
      eRickshawFare: 10,
      avgPgRent: 10500,
      safetyIndex: 4.6,
      description: 'Right next to Malkaganj and Kamla Nagar markets. Vishwa Vidyalaya station is the primary transit gateway. Shared rickshaws run round the clock.',
    ),
    CampusGuideItem(
      id: 'lsr_guide',
      collegeName: 'Lady Shri Ram College (LSR)',
      campusType: 'south',
      nearestMetro: 'Moolchand',
      metroLine: 'Violet',
      walkingDistanceMins: 8,
      eRickshawFare: 15,
      avgPgRent: 14000,
      safetyIndex: 4.9,
      description: 'Premium South Campus girls college. Situated near Moolchand station on the Violet line. PGs are usually available in Lajpat Nagar, Kailash Colony, and Amar Colony.',
    ),
    CampusGuideItem(
      id: 'venky_guide',
      collegeName: 'Sri Venkateswara College',
      campusType: 'south',
      nearestMetro: 'Durgabai Deshmukh South Campus',
      metroLine: 'Pink',
      walkingDistanceMins: 6,
      eRickshawFare: 10,
      avgPgRent: 12500,
      safetyIndex: 4.7,
      description: 'Venky is located right on Benito Juarez Marg. Durgabai Deshmukh South Campus station on the Pink line connects directly via a foot overbridge walkway. PGs are concentrated in Satya Niketan.',
    ),
    CampusGuideItem(
      id: 'dyalsingh_guide',
      collegeName: 'Dyal Singh College',
      campusType: 'off',
      nearestMetro: 'JLN Stadium',
      metroLine: 'Violet',
      walkingDistanceMins: 5,
      eRickshawFare: 10,
      avgPgRent: 9500,
      safetyIndex: 4.3,
      description: 'Centrally located Off-Campus college on Lodhi Road. Nearest station is JLN Stadium on Violet Line, just a 5-minute walk from college gates.',
    ),
  ];

  DuCampusService() {
    fetchGuides();
  }

  // Load guides from Supabase or fallback
  Future<void> fetchGuides() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _client
          .from('du_campus_guides')
          .select()
          .order('college_name', ascending: true);

      if (response != null && response is List) {
        _guides = response.map((item) => CampusGuideItem.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching campus guides from Supabase (loading mock defaults): $e');
      if (_guides.isEmpty) {
        _guides = List.from(_seededGuides);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add or update campus guide item (Controllable by Admin!)
  Future<bool> addOrUpdateGuide(CampusGuideItem item) async {
    // Optimistic cache update
    final index = _guides.indexWhere((g) => g.id == item.id);
    if (index != -1) {
      _guides[index] = item;
    } else {
      _guides.add(item);
    }
    notifyListeners();

    try {
      await _client.from('du_campus_guides').upsert(item.toJson());
      return true;
    } catch (e) {
      debugPrint('Failed to save guide to Supabase (working offline): $e');
      return false;
    }
  }

  // Delete guide item
  Future<bool> deleteGuide(String id) async {
    _guides.removeWhere((g) => g.id == id);
    notifyListeners();

    try {
      await _client.from('du_campus_guides').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Failed to delete guide from database: $e');
      return false;
    }
  }
}
