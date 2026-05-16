import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/du_models.dart';
import 'du_college_detail_screen.dart';

class DuCollegeDiscoveryScreen extends StatefulWidget {
  const DuCollegeDiscoveryScreen({super.key});

  @override
  State<DuCollegeDiscoveryScreen> createState() => _DuCollegeDiscoveryScreenState();
}

class _DuCollegeDiscoveryScreenState extends State<DuCollegeDiscoveryScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  
  List<DuCollegeData> _allColleges = [];
  List<DuCollegeData> _filteredColleges = [];
  bool _isLoading = true;
  
  String _searchQuery = '';
  String _selectedCampus = 'All';
  final List<String> _campuses = ['All', 'North Campus', 'South Campus', 'Off Campus'];

  @override
  void initState() {
    super.initState();
    _fetchColleges();
  }

  Future<void> _fetchColleges() async {
    try {
      final res = await _client.from('du_college_details').select();
      final List<DuCollegeData> colleges = (res as List).map((c) => DuCollegeData.fromJson(c)).toList();
      setState(() {
        _allColleges = colleges;
        _filteredColleges = colleges;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filter() {
    setState(() {
      _filteredColleges = _allColleges.where((c) {
        final matchSearch = _searchQuery.isEmpty || 
            c.collegeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (c.nearestMetro?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        
        final campus = c.campusType?.toLowerCase().trim() ?? '';
        final selected = _selectedCampus.toLowerCase().trim();
        
        final matchCampus = _selectedCampus == 'All' || 
            campus == selected ||
            (selected == 'off campus' && (campus.isEmpty || campus.contains('off')));
        
        return matchSearch && matchCampus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Explore DU Colleges', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) {
                    _searchQuery = v;
                    _filter();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search college or nearby metro...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _campuses.map((campus) {
                      final isSelected = _selectedCampus == campus;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(campus, style: GoogleFonts.outfit(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCampus = campus);
                              _filter();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _filteredColleges.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredColleges.length,
                    itemBuilder: (context, index) {
                      final college = _filteredColleges[index];
                      return _buildCollegeCard(context, college);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollegeCard(BuildContext context, DuCollegeData college) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DuCollegeDetailScreen(
              college: college,
              category: 'UR',
              round: 1,
              year: 2025,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  college.mainImageUrl ?? '', 
                  width: 80, 
                  height: 80, 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80, 
                    height: 80, 
                    color: Colors.grey.shade200,
                    child: const Icon(LucideIcons.building2, color: Colors.grey),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 80, 
                      height: 80, 
                      color: Colors.grey.shade100,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(college.collegeName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(college.campusType ?? 'Off Campus', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(LucideIcons.train, size: 12, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(college.nearestMetro ?? 'DU Campus', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.building, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No colleges found', style: GoogleFonts.outfit(color: Colors.grey)),
        ],
      ),
    );
  }
}
