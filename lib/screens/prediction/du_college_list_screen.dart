import 'package:cuet/screens/prediction/du_college_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/du_models.dart';
import '../../providers/du_wishlist_provider.dart';
import 'du_program_list_screen.dart';

class DuCollegeListScreen extends StatefulWidget {
  final List<DuCollegeData> colleges;
  final String category;
  final int year;

  const DuCollegeListScreen({
    super.key,
    required this.colleges,
    required this.category,
    required this.year,
  });

  @override
  State<DuCollegeListScreen> createState() => _DuCollegeListScreenState();
}

class _DuCollegeListScreenState extends State<DuCollegeListScreen> {
  String _currentCategory = '';
  bool _isLoading = false;

  final List<String> _categories = [
    'Unreserved',
    'OBC-NCL',
    'SC',
    'ST',
    'EWS',
    'Sikh',
    'Christian',
  ];

  String _searchQuery = '';
  String? _selectedCourse;
  List<DuCollegeData> _filteredColleges = [];

  String _getUserBestScoreDisplay() {
    if (widget.colleges.isEmpty) return '0 / 1000';
    double bestScore = 0.0;
    int maxScoreForBest = 1000;
    for (var c in widget.colleges) {
      for (var p in c.programs) {
        if (p.userScore > bestScore) {
          bestScore = p.userScore;
          maxScoreForBest = p.maxScore;
        }
      }
    }
    return '${bestScore.toInt()} / $maxScoreForBest';
  }

  List<String> _getAllPrograms() {
    final set = <String>{};
    for (var c in widget.colleges) {
      for (var p in c.programs) {
        set.add(p.programName);
      }
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  @override
  void initState() {
    super.initState();
    _filteredColleges = widget.colleges;
    _currentCategory = widget.category;
  }

  Future<void> _updateResults() async {
    setState(() => _isLoading = true);
    try {
      _filter(_searchQuery);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filter(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty && _selectedCourse == null) {
        _filteredColleges = widget.colleges;
      } else {
        _filteredColleges = widget.colleges.where((c) {
          final q = query.toLowerCase();
          final matchSearch = query.isEmpty || 
              c.collegeName.toLowerCase().contains(q) ||
              c.programs.any((p) => p.programName.toLowerCase().contains(q));
          
          final matchCourse = _selectedCourse == null || 
              c.programs.any((p) => p.programName == _selectedCourse);

          return matchSearch && matchCourse;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate total programs
    int totalPrograms = widget.colleges.fold(
      0,
      (sum, c) => sum + c.programs.length,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DU Predictor Results',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.filter),
            onPressed: () {}, // Future: advanced filters
          ),
        ],
      ),
      body: Column(
        children: [
          // User Score Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles, color: Colors.white, size: 28),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Best Merit Score', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                    Text(_getUserBestScoreDisplay(), style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(widget.category, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Course Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Filter by Courses', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All Courses'),
                    selected: _selectedCourse == null,
                    onSelected: (_) => setState(() => _selectedCourse = null),
                  ),
                ),
                ..._getAllPrograms().map((prog) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(prog),
                      selected: _selectedCourse == prog,
                      onSelected: (selected) {
                        setState(() => _selectedCourse = selected ? prog : null);
                        _filter(_searchQuery);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _filter,
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                hintText: 'Search college or program...',
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredColleges.length} Colleges',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '•  $totalPrograms Programs',
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _filteredColleges.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.searchX, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No colleges found for this criteria.',
                            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No colleges found. Try adjusting your category or subjects. Ensure you selected at least one Language (List A) subject, as it is required for most DU programs.',
                            style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredColleges.length,
                    itemBuilder: (context, index) {
                      final college = _filteredColleges[index];
                      return _buildCollegeCard(context, college, theme, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollegeCard(
    BuildContext context,
    DuCollegeData college,
    ThemeData theme,
    bool isDark,
  ) {
    final bestProgram = college.programs.first;
    final double diff = bestProgram.difference;

    String chanceLabel;
    Color chanceColor;
    IconData chanceIcon;

    if (diff >= 0) {
      chanceLabel = 'High Chance';
      chanceColor = Colors.green;
      chanceIcon = LucideIcons.checkCircle2;
    } else {
      chanceLabel = 'Low Chance';
      chanceColor = Colors.orange;
      chanceIcon = LucideIcons.alertCircle;
    }

    final wishlist = Provider.of<DuWishlistProvider>(context);
    final isWishlisted = wishlist.isWishlisted(college.collegeName);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Logo
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: college.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            college.logoUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(LucideIcons.building2,
                                    color: Colors.grey),
                          ),
                        )
                      : const Icon(LucideIcons.building2, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        college.collegeName,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${college.programs.length} Eligible Programs',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Chance Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: chanceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(chanceIcon, size: 13, color: chanceColor),
                      const SizedBox(width: 4),
                      Text(
                        chanceLabel,
                        style: GoogleFonts.outfit(
                          color: chanceColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Wishlist heart
                GestureDetector(
                  onTap: () {
                    wishlist.toggle(college);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isWishlisted
                              ? '${college.collegeName} removed from wishlist'
                              : '${college.collegeName} added to wishlist ❤️',
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        isWishlisted
                            ? LucideIcons.heart
                            : LucideIcons.heart,
                        key: ValueKey(isWishlisted),
                        color: isWishlisted
                            ? Colors.red
                            : Colors.grey.shade400,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DuProgramListScreen(
                            collegeData: college,
                            category: widget.category,
                            year: widget.year,
                          ),
                        ),
                      );
                    },
                    child: const Text('Programs'),
                  ),
                ),
                const SizedBox(width: 12),
                if (college.id != 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DuCollegeDetailScreen(
                              college: college,
                              category: widget.category,
                              year: widget.year,
                            ),
                          ),
                        );
                      },
                      child: const Text('Details'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
