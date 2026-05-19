import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_service.dart';
import '../../providers/cutoff_provider.dart';
import '../../providers/du_preference_service.dart';
import '../../models/du_models.dart';

class PreferenceGeneratorScreen extends StatefulWidget {
  const PreferenceGeneratorScreen({super.key});

  @override
  State<PreferenceGeneratorScreen> createState() => _PreferenceGeneratorScreenState();
}

class _PreferenceGeneratorScreenState extends State<PreferenceGeneratorScreen> {
  int _currentStep = 0;

  // Selected courses list
  final Set<String> _selectedCourses = {};

  // Preferences
  String _selectedCampus = 'Balanced'; // 'North Campus', 'South Campus', 'Balanced'
  String _selectedPriority = 'Balanced'; // 'NIRF Ranking', 'Placements', 'Cutoffs', 'Balanced'

  // Results
  List<Map<String, dynamic>> _generatedSheet = [];
  bool _isGenerating = false;

  // Course categories
  final Map<String, List<String>> _courseCategories = {
    'Commerce & Management': [
      'B.Com. (Hons.)',
      'B.Com.',
      'B.A. (Hons.) Economics',
      'Bachelor of Management Studies (BMS)',
      'Bachelor of Business Administration (FIA)',
    ],
    'Sciences': [
      'B.Sc. (Hons.) Computer Science',
      'B.Sc. (Hons.) Physics',
      'B.Sc. (Hons.) Chemistry',
      'B.Sc. (Hons.) Mathematics',
      'B.Sc. (Hons.) Statistics',
      'B.Sc. (Hons.) Botany',
      'B.Sc. (Hons.) Zoology',
      'B.Sc. Physical Science with Computer Science',
      'B.Sc. Life Sciences',
    ],
    'Arts & Humanities': [
      'B.A. (Hons.) English',
      'B.A. (Hons.) Political Science',
      'B.A. (Hons.) History',
      'B.A. (Hons.) Sociology',
      'B.A. (Hons.) Psychology',
      'B.A. (Hons.) Geography',
      'B.A. (Hons.) Journalism',
      'B.A. (Programme)',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(
          'Preference Sheet Generator',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            _buildStepIndicator(isDark),
            
            Expanded(
              child: _buildStepContent(theme, isDark),
            ),
            
            // Bottom navigation buttons
            _buildBottomNav(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    final steps = ['Select Courses', 'Preferences', 'Your Sheet'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C24) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isCompleted = _currentStep > index;
          final isActive = _currentStep == index;
          return Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : isCompleted
                          ? Colors.green
                          : isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : isCompleted
                            ? Colors.green
                            : Colors.grey.shade300,
                  ),
                ),
                child: isCompleted
                    ? const Icon(LucideIcons.check, color: Colors.white, size: 16)
                    : Text(
                        '${index + 1}',
                        style: GoogleFonts.outfit(
                          color: isActive || isCompleted
                              ? Colors.white
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Text(
                steps[index],
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              ),
              if (index < steps.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme, bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildCourseSelectionStep(theme, isDark);
      case 1:
        return _buildPreferencesStep(theme, isDark);
      case 2:
        return _buildResultsStep(theme, isDark);
      default:
        return const SizedBox();
    }
  }

  Widget _buildCourseSelectionStep(ThemeData theme, bool isDark) {
    return DefaultTabController(
      length: _courseCategories.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What programs are you targetting?',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select all programs you want to include in your preference list.',
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          
          TabBar(
            isScrollable: true,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.colorScheme.primary,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: _courseCategories.keys.map((cat) => Tab(text: cat)).toList(),
          ),
          
          Expanded(
            child: TabBarView(
              children: _courseCategories.entries.map((entry) {
                final courses = entry.value;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    final isSelected = _selectedCourses.contains(course);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        activeColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          course,
                          style: GoogleFonts.outfit(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          entry.key,
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedCourses.add(course);
                            } else {
                              _selectedCourses.remove(course);
                            }
                          });
                        },
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesStep(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customize Your Ranking Weights',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tell us how you would like to rank the colleges offering your selected courses.',
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 32),
          
          // Campus Priority Selection
          Text(
            'Campus Location Priority',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildChoiceGroup(
            options: ['North Campus', 'South Campus', 'Balanced'],
            selected: _selectedCampus,
            onSelected: (val) => setState(() => _selectedCampus = val),
            theme: theme,
            isDark: isDark,
          ),
          
          const SizedBox(height: 32),
          
          // Main Ranking Factor Selection
          Text(
            'Primary Evaluation Metric',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'This factor will carry the highest mathematical weight when sorting.',
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          
          _buildPriorityOption(
            title: 'Balanced Algorithm (Recommended)',
            desc: 'A weighted combination of placements, NIRF rank, and cutoffs.',
            value: 'Balanced',
            icon: LucideIcons.scale,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildPriorityOption(
            title: 'Placement Packages',
            desc: 'Sorts primarily based on the highest and average salary packages.',
            value: 'Placements',
            icon: LucideIcons.banknote,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildPriorityOption(
            title: 'Official NIRF Rankings',
            desc: 'Sorts strictly using the national institutional framework ranking.',
            value: 'NIRF Ranking',
            icon: LucideIcons.award,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildPriorityOption(
            title: 'Cutoff Score Prestige',
            desc: 'Sorts by general competitiveness (highest cutoffs first).',
            value: 'Cutoffs',
            icon: LucideIcons.trendingUp,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceGroup({
    required List<String> options,
    required String selected,
    required Function(String) onSelected,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Row(
      children: options.map((opt) {
        final isSel = selected == opt;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () => onSelected(opt),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSel
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : isDark
                          ? const Color(0xFF161C24)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSel
                        ? theme.colorScheme.primary
                        : isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  opt,
                  style: GoogleFonts.outfit(
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    color: isSel ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriorityOption({
    required String title,
    required String desc,
    required String value,
    required IconData icon,
    required ThemeData theme,
  }) {
    final isSel = _selectedPriority == value;
    return InkWell(
      onTap: () => setState(() => _selectedPriority = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSel ? theme.colorScheme.primary : theme.dividerColor,
            width: isSel ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSel
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSel ? theme.colorScheme.primary : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSel ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: GoogleFonts.outfit(
                      color: Colors.grey,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSel)
              Icon(
                LucideIcons.checkCircle2,
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsStep(ThemeData theme, bool isDark) {
    if (_isGenerating) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Evaluating matching colleges...'),
          ],
        ),
      );
    }

    if (_generatedSheet.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No Colleges Found',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'We could not find any matching colleges for the selected programs. Go back and select different programs.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Top info header
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.primary.withOpacity(0.05),
          child: Row(
            children: [
              Icon(LucideIcons.info, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '💡 Drag and drop items (hold and move) to custom-rank them as per your absolute liking!',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.primary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Generated preferences list
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _generatedSheet.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = _generatedSheet.removeAt(oldIndex);
                _generatedSheet.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final item = _generatedSheet[index];
              return Card(
                key: ValueKey(item['collegeName'] + item['programName']),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Rank badge
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: index < 3
                              ? theme.colorScheme.primary
                              : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.outfit(
                            color: index < 3 ? Colors.white : theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // College Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['collegeName'] ?? '',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['programName'] ?? '',
                              style: GoogleFonts.outfit(
                                color: theme.colorScheme.secondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            
                            // Stats Badges
                            Row(
                              children: [
                                if (item['nirf'] != null && item['nirf'] != 0) ...[
                                  Icon(LucideIcons.award, size: 12, color: Colors.amber.shade700),
                                  const SizedBox(width: 2),
                                  Text(
                                    'NIRF #${item['nirf']}',
                                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                if (item['campus'] != null) ...[
                                  const Icon(LucideIcons.mapPin, size: 12, color: Colors.grey),
                                  const SizedBox(width: 2),
                                  Text(
                                    item['campus'],
                                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const Icon(LucideIcons.gripVertical, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Action Buttons: Save & Share
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportToClipboard,
                  icon: const Icon(LucideIcons.copy),
                  label: const Text('Copy List'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _savePreferenceSheet,
                  icon: const Icon(LucideIcons.checkCircle),
                  label: const Text('Save & Submit'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(ThemeData theme) {
    if (_currentStep == 2) return const SizedBox(); // Result screen has its own bottom buttons

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Back'),
            )
          else
            const SizedBox(),
            
          ElevatedButton(
            onPressed: _currentStep == 0 && _selectedCourses.isEmpty ? null : _handleNextStep,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(_currentStep == 1 ? 'Generate Sheet' : 'Continue'),
          ),
        ],
      ),
    );
  }

  void _handleNextStep() {
    if (_currentStep == 1) {
      _generatePreferences();
    } else {
      setState(() => _currentStep++);
    }
  }

  // CORE PREFERENCE RANKING ALGORITHM
  Future<void> _generatePreferences() async {
    setState(() {
      _currentStep = 2;
      _isGenerating = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final cutoffProvider = Provider.of<CutoffProvider>(context, listen: false);

      // 1. Fetch all college details from Supabase to get NIRF rank & placements
      final collegesRes = await supabase.from('du_college_details').select();
      final List<DuCollegeDetails> allColleges = (collegesRes as List)
          .map((json) => DuCollegeDetails.fromJson(json))
          .toList();

      final Map<String, DuCollegeDetails> collegesMap = {
        for (var c in allColleges) c.collegeName.trim().toLowerCase(): c
      };

      // 2. Identify offered colleges & cutoffs for selected courses
      final List<Map<String, dynamic>> rawCombinations = [];

      for (final selectedCourse in _selectedCourses) {
        for (final college in cutoffProvider.getProgramsForCollege('')) {
          // Wait, getProgramsForCollege requires college. Let's iterate over colleges in cutoffs data.
          // Let's use cutoffProvider._data keys directly or fetch programs for each college in collegesMap.
        }

        // Safer approach: Retrieve all programs offered across our data
        // Let's look at cutoffProvider._data to fetch all matches
        final data = cutoffProvider.getAllCategoriesForProgram('', ''); // placeholder
      }

      // To make it highly reliable, we parse our cutoffs from cutoffProvider!
      // Since cutoffProvider has the _data map loaded, we can traverse it
      // Let's use getCutoff point lookup or pull from our college list
      final allCollegesInCutoffs = allColleges.map((c) => c.collegeName).toList();
      
      for (final selectedCourse in _selectedCourses) {
        for (final collegeName in allCollegesInCutoffs) {
          final cutoffScore = cutoffProvider.getCutoff(collegeName, selectedCourse, 'General');
          if (cutoffScore != null && cutoffScore > 0) {
            final colDetails = collegesMap[collegeName.trim().toLowerCase()];
            rawCombinations.add({
              'collegeName': collegeName,
              'programName': selectedCourse,
              'cutoffScore': cutoffScore,
              'collegeDetails': colDetails,
            });
          }
        }
      }

      // 3. Apply scoring based on user selections
      final scoredList = rawCombinations.map((item) {
        final DuCollegeDetails? details = item['collegeDetails'];
        final double cutoffScore = item['cutoffScore'];
        
        final double nirfRank = (details?.nirfRanking ?? 100).toDouble();
        final double placementAvg = details?.placementAvg ?? 4.5; // fallback average package

        // Scale factors:
        // NIRF Score: Lower rank is better. #1 rank -> 100 points, #100 -> 0 points.
        final double nirfScore = (100 - nirfRank).clamp(0.0, 100.0);
        
        // Placement Score: average package scaled. e.g. 5 LPA -> 50 points.
        final double placementScore = (placementAvg * 10).clamp(0.0, 100.0);
        
        // Cutoff Score: e.g. 780 out of 800 -> scale to 100.
        final double cutoffNormalized = (cutoffScore / 8).clamp(0.0, 100.0);

        // Location priority bonus (North/South Campus focus)
        double campusBonus = 0.0;
        final campus = details?.campusType?.toLowerCase() ?? '';
        if (_selectedCampus == 'North Campus' && campus.contains('north')) {
          campusBonus = 25.0;
        } else if (_selectedCampus == 'South Campus' && campus.contains('south')) {
          campusBonus = 25.0;
        }

        // Apply weights based on selection
        double totalScore = 0.0;
        if (_selectedPriority == 'NIRF Ranking') {
          totalScore = (nirfScore * 0.6) + (placementScore * 0.2) + (cutoffNormalized * 0.2) + campusBonus;
        } else if (_selectedPriority == 'Placements') {
          totalScore = (nirfScore * 0.2) + (placementScore * 0.6) + (cutoffNormalized * 0.2) + campusBonus;
        } else if (_selectedPriority == 'Cutoffs') {
          totalScore = (nirfScore * 0.2) + (placementScore * 0.2) + (cutoffNormalized * 0.6) + campusBonus;
        } else {
          // Balanced/Reputation
          totalScore = (nirfScore * 0.35) + (placementScore * 0.35) + (cutoffNormalized * 0.3) + campusBonus;
        }

        return {
          'collegeName': item['collegeName'],
          'programName': item['programName'],
          'nirf': details?.nirfRanking ?? 0,
          'campus': details?.campusType ?? 'Off Campus',
          'score': totalScore,
        };
      }).toList();

      // 4. Sort and set generated sheet
      scoredList.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

      setState(() {
        _generatedSheet = scoredList;
        _isGenerating = false;
      });
    } catch (e) {
      debugPrint('Error generating preferences: $e');
      setState(() => _isGenerating = false);
    }
  }

  void _exportToClipboard() {
    if (_generatedSheet.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('🎓 CSAS PREFERENCE SHEET GENERATOR REPORT (DUVerse) 🎓');
    buffer.writeln('Campus Preference: $_selectedCampus | Priority Factor: $_selectedPriority');
    buffer.writeln('========================================================================\n');
    
    for (int i = 0; i < _generatedSheet.length; i++) {
      final item = _generatedSheet[i];
      buffer.writeln('${i + 1}. ${item['collegeName']} — ${item['programName']} (${item['campus']})');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully copied preference sheet to clipboard! 📋'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _savePreferenceSheet() async {
    final prefService = Provider.of<DuPreferenceService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    final user = authService.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? 'Student';
    final userEmail = user?.email ?? 'No email';

    final parsedSheetData = _generatedSheet.asMap().entries.map((e) => {
      'collegeName': e.value['collegeName'],
      'programName': e.value['programName'],
      'rank': e.key + 1,
    }).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final isSavedToSupabase = await prefService.savePreferenceSheet(
      userName: userName,
      userEmail: userEmail,
      targetCourses: _selectedCourses.toList(),
      campusPreference: _selectedCampus,
      priorityFactor: _selectedPriority,
      sheetData: parsedSheetData,
    );

    if (mounted) {
      Navigator.pop(context); // Pop loading dialog
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(
                isSavedToSupabase ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                color: isSavedToSupabase ? Colors.green : Colors.amber,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isSavedToSupabase ? 'Report Saved Successfully!' : 'Saved to Local Cache!',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            isSavedToSupabase
                ? 'Your preference sheet has been fully saved to the admin dashboard and student reports database!'
                : 'Your preference sheet is saved in offline cache. To sync with the admin database, ask the admin to run table migrations.',
            style: GoogleFonts.outfit(),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Pop alert
                Navigator.pop(context); // Return home
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Awesome'),
            ),
          ],
        ),
      );
    }
  }
}
