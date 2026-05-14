import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/mock_data.dart';
import '../college/college_details_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/user_score_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/filter_provider.dart';
import '../../providers/compare_provider.dart';
import '../../models/college_model.dart';
import '../compare/compare_screen.dart';

class PredictionResultsScreen extends StatefulWidget {
  const PredictionResultsScreen({super.key});

  @override
  State<PredictionResultsScreen> createState() => _PredictionResultsScreenState();
}

class _PredictionResultsScreenState extends State<PredictionResultsScreen> {
  bool _isSearching = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final filterProvider = Provider.of<FilterProvider>(context, listen: false);
    _searchController = TextEditingController(text: filterProvider.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scoreProvider = Provider.of<UserScoreProvider>(context);
    final filterProvider = Provider.of<FilterProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final compareProvider = Provider.of<CompareProvider>(context);
    
    final userScore = scoreProvider.score.getTotalScore(false);
    final category = scoreProvider.score.category;

    // Filter Logic
    final filteredColleges = MockData.colleges.where((CollegeModel college) {
      // Search Filter
      if (filterProvider.searchQuery.isNotEmpty &&
          !college.name.toLowerCase().contains(filterProvider.searchQuery.toLowerCase())) {
        return false;
      }
      // Campus Filter
      if (filterProvider.selectedCampuses.isNotEmpty &&
          !filterProvider.selectedCampuses.contains(college.campus)) {
        return false;
      }
      // Type Filter
      if (filterProvider.selectedTypes.isNotEmpty &&
          !filterProvider.selectedTypes.contains(college.type)) {
        return false;
      }
      // Course Filter
      if (filterProvider.selectedCourse != null) {
        bool hasCourse = college.courses.any((c) => c.courseName == filterProvider.selectedCourse);
        if (!hasCourse) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search colleges...',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.outfit(color: Colors.grey),
                ),
                style: GoogleFonts.outfit(),
                onChanged: (val) => filterProvider.setSearchQuery(val),
              )
            : const Text('Eligible Colleges'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? LucideIcons.x : LucideIcons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  filterProvider.setSearchQuery('');
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              LucideIcons.filter,
              color: filterProvider.hasFilters && !_isSearching ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
          ),
        ],
      ),
      body: filteredColleges.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.searchX, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No colleges found',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search or filters',
                  style: GoogleFonts.outfit(color: Colors.grey),
                ),
                TextButton(
                  onPressed: () {
                    filterProvider.resetFilters();
                    _searchController.clear();
                    setState(() {
                      _isSearching = false;
                    });
                  },
                  child: const Text('Reset All'),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredColleges.length,
            itemBuilder: (context, index) {
              final college = filteredColleges[index];
              final isInCompare = compareProvider.isInCompare(college.id);
              
              CourseCutoff relevantCourse = college.courses.first;
              if (filterProvider.selectedCourse != null) {
                relevantCourse = college.courses.firstWhere(
                  (c) => c.courseName == filterProvider.selectedCourse,
                  orElse: () => college.courses.first,
                );
              }
              
              double expectedCutoff = relevantCourse.cutoffs[category]?.expected2026 ?? 800;
              
              String chance;
              Color chanceColor;
              
              if (userScore >= expectedCutoff) {
                chance = 'High Chance';
                chanceColor = Colors.green;
              } else if (userScore >= expectedCutoff - 10) {
                chance = 'Medium Chance';
                chanceColor = Colors.orange;
              } else {
                chance = 'Low Chance';
                chanceColor = Colors.red;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CollegeDetailsScreen(college: college)),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  college.logoUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.building2, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    college.name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${college.campus} • ${college.type}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    wishlistProvider.isInWishlist(college.id) 
                                        ? LucideIcons.heart
                                        : LucideIcons.heart,
                                  ),
                                  color: wishlistProvider.isInWishlist(college.id)
                                      ? Colors.red
                                      : Colors.grey.shade400,
                                  onPressed: () {
                                    final wasInWishlist = wishlistProvider.isInWishlist(college.id);
                                    wishlistProvider.toggleWishlist(college);
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          wasInWishlist 
                                              ? '${college.name} removed' 
                                              : '${college.name} added to list'
                                        ),
                                        duration: const Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    isInCompare ? LucideIcons.checkCircle2 : LucideIcons.plusCircle,
                                    size: 20,
                                  ),
                                  color: isInCompare ? Colors.orange : Colors.grey.shade400,
                                  onPressed: () {
                                    if (!isInCompare && compareProvider.count >= 2) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('You can only compare 2 colleges at a time.'))
                                      );
                                      return;
                                    }
                                    compareProvider.toggleCompare(college);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  filterProvider.selectedCourse ?? relevantCourse.courseName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: chanceColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    chance,
                                    style: GoogleFonts.outfit(
                                      color: chanceColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Expected Cutoff',
                                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                Text(
                                  '${expectedCutoff.toInt()}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      floatingActionButton: compareProvider.count == 2
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompareScreen(
                      college1: compareProvider.compareList[0],
                      college2: compareProvider.compareList[1],
                    ),
                  ),
                );
              },
              backgroundColor: Colors.orange,
              icon: const Icon(LucideIcons.arrowLeftRight, color: Colors.white),
              label: Text(
                'Compare Now',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          : null,
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const FilterBottomSheet(),
    );
  }
}

class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final filterProvider = Provider.of<FilterProvider>(context);
    final theme = Theme.of(context);

    // Get unique courses for the filter
    final allCourses = MockData.colleges
        .expand((CollegeModel c) => c.courses)
        .map((c) => c.courseName)
        .toSet()
        .toList();
    allCourses.sort();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => filterProvider.resetFilters(),
                  child: const Text('Reset All'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Campus Filter
            Text(
              'Campus',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['North Campus', 'South Campus', 'Off Campus'].map((campus) {
                final isSelected = filterProvider.selectedCampuses.contains(campus);
                return FilterChip(
                  label: Text(campus, style: GoogleFonts.outfit()),
                  selected: isSelected,
                  onSelected: (_) => filterProvider.toggleCampus(campus),
                  selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: theme.colorScheme.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Type Filter
            Text(
              'College Type',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['Government', 'Private'].map((type) {
                final isSelected = filterProvider.selectedTypes.contains(type);
                return FilterChip(
                  label: Text(type, style: GoogleFonts.outfit()),
                  selected: isSelected,
                  onSelected: (_) => filterProvider.toggleType(type),
                  selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: theme.colorScheme.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Course Filter
            Text(
              'Course',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  hint: Text('Select a course', style: GoogleFonts.outfit()),
                  value: filterProvider.selectedCourse,
                  isExpanded: true,
                  icon: const Icon(LucideIcons.chevronDown),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Courses'),
                    ),
                    ...allCourses.map((course) {
                      return DropdownMenuItem<String>(
                        value: course,
                        child: Text(course, style: GoogleFonts.outfit()),
                      );
                    }),
                  ],
                  onChanged: (val) => filterProvider.setCourse(val),
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Apply Filters',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
