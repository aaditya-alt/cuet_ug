import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_service.dart';
import '../../providers/du_preference_service.dart';
import '../../models/du_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _PrefItem {
  final String collegeName;
  final String programName;
  final String campus;
  final int? nirfRank;
  final double? placementAvg;
  final double? placementHighest;
  final double cutoffScore;
  final String? naacGrade;
  double score;

  _PrefItem({
    required this.collegeName,
    required this.programName,
    required this.campus,
    required this.nirfRank,
    required this.placementAvg,
    required this.placementHighest,
    required this.cutoffScore,
    required this.naacGrade,
    required this.score,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY MAPPING  — UI label → DB value in du_cutoffs.category
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, String> _categoryDbMap = {
  'General (UR)': 'UR',
  'OBC (NCL)': 'OBC',
  'SC': 'SC',
  'ST': 'ST',
  'EWS': 'EWS',
  'PwBD': 'PwBD',
};

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class PreferenceGeneratorScreen extends StatefulWidget {
  const PreferenceGeneratorScreen({super.key});

  @override
  State<PreferenceGeneratorScreen> createState() =>
      _PreferenceGeneratorScreenState();
}

class _PreferenceGeneratorScreenState extends State<PreferenceGeneratorScreen> {
  int _currentStep = 0;

  // Step 1
  final Set<String> _selectedCourses = {};
  bool _loadingCourses = true;
  Map<String, List<String>> _courseCategories = {};

  // Step 2
  String _selectedCampus = 'Balanced';
  String _selectedPriority = 'Balanced';
  String _selectedGenderUi = 'All'; // UI: 'All', 'Girls', 'Boys'
  String _selectedCategoryUi = 'General (UR)'; // UI label

  // Step 3
  List<_PrefItem> _generatedSheet = [];
  bool _isGenerating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCourseList();
  }

  // ─── Fetch ALL distinct program names (paginated) ─────────────────────────
  Future<void> _loadCourseList() async {
    setState(() => _loadingCourses = true);
    try {
      final supabase = Supabase.instance.client;

      // Paginate to get all program names — DB has 2094+ rows
      final Set<String> programs = {};
      int offset = 0;
      const batch = 1000;
      while (true) {
        final res = await supabase
            .from('du_cutoffs')
            .select('program_name')
            .range(offset, offset + batch - 1);
        final list = res as List;
        for (final r in list) {
          final name = (r['program_name'] as String).trim();
          // Skip B.A Programme combination rows — those are college-specific
          if (!name.startsWith('B.A Program') &&
              !name.startsWith('B.A. Program')) {
            programs.add(name);
          }
        }
        if (list.length < batch) break;
        offset += batch;
      }

      final sorted = programs.toList()..sort();

      // Auto-categorise
      final Map<String, List<String>> cats = {
        'Commerce & Management': [],
        'Sciences': [],
        'Arts & Humanities': [],
        'Education & Vocational': [],
        'Other': [],
      };

      for (final p in sorted) {
        final l = p.toLowerCase();
        if (l.contains('b.com') ||
            l.contains('economics') ||
            l.contains('bms') ||
            l.contains('bachelor of management') ||
            l.contains('business') ||
            l.contains('fia') ||
            l.contains('financial investment')) {
          cats['Commerce & Management']!.add(p);
        } else if (l.contains('b.sc') ||
            l.contains('computer') ||
            l.contains('physics') ||
            l.contains('chemistry') ||
            l.contains('mathematics') ||
            l.contains('statistics') ||
            l.contains('botany') ||
            l.contains('zoology') ||
            l.contains('life science') ||
            l.contains('applied') ||
            l.contains('electronics') ||
            l.contains('instrumentation') ||
            l.contains('biochemistry') ||
            l.contains('microbiology') ||
            l.contains('geology') ||
            l.contains('polymer') ||
            l.contains('b.tech')) {
          cats['Sciences']!.add(p);
        } else if (l.contains('b.voc') ||
            l.contains('b.el.ed') ||
            l.contains('elementary education') ||
            l.contains('vocational') ||
            l.contains('bachelor of fine arts') ||
            l.contains('bfa')) {
          cats['Education & Vocational']!.add(p);
        } else if (l.contains('b.a')) {
          cats['Arts & Humanities']!.add(p);
        } else {
          cats['Other']!.add(p);
        }
      }

      cats.removeWhere((_, v) => v.isEmpty);

      if (mounted) {
        setState(() {
          _courseCategories = cats;
          _loadingCourses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCourses = false;
          _errorMessage = 'Could not load programs: $e';
        });
      }
    }
  }

  // ─── Core ranking algorithm ───────────────────────────────────────────────
  Future<void> _generatePreferences() async {
    setState(() {
      _currentStep = 2;
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // Map UI category label → DB value
      final dbCategory = _categoryDbMap[_selectedCategoryUi] ?? 'UR';

      // ── 1. Fetch college details ──────────────────────────────────────────
      final collegesRes = await supabase.from('du_college_details').select();
      final Map<String, Map<String, dynamic>> collegeMap = {};
      for (final row in collegesRes as List) {
        final name = (row['college_name'] as String).trim().toLowerCase();
        collegeMap[name] = row;
      }

      // ── 2. Fetch ALL cutoffs (paginated) for selected programs + category ─
      // DB gender values: 'Co-Ed' or 'Female'
      // Male student → only 'Co-Ed'
      // Female student → 'Co-Ed' AND 'Female'
      // All → both

      final List<Map<String, dynamic>> allCutoffs = [];
      final programsList = _selectedCourses.toList();

      // Supabase .inFilter has limits — chunk if large selection
      const chunkSize = 50;
      final chunks = <List<String>>[];
      for (int i = 0; i < programsList.length; i += chunkSize) {
        chunks.add(
          programsList.sublist(
            i,
            i + chunkSize > programsList.length
                ? programsList.length
                : i + chunkSize,
          ),
        );
      }

      for (final chunk in chunks) {
        int offset = 0;
        const batch = 1000;
        while (true) {
          var query = supabase
              .from('du_cutoffs')
              .select(
                'college_name, college_name_canonical, program_name, category, gender, cutoff_score',
              )
              .inFilter('program_name', chunk)
              .eq('category', dbCategory)
              .range(offset, offset + batch - 1);

          // Gender filter using DB values
          if (_selectedGenderUi == 'Boys') {
            query = supabase
                .from('du_cutoffs')
                .select(
                  'college_name, college_name_canonical, program_name, category, gender, cutoff_score',
                )
                .inFilter('program_name', chunk)
                .eq('category', dbCategory)
                .eq('gender', 'Co-Ed')
                .range(offset, offset + batch - 1);
          }
          // Girls and All: include both Co-Ed and Female — no filter needed
          // (for Girls we show both, let college details tell them it's women's)

          final res = await query;
          final list = List<Map<String, dynamic>>.from(res);
          allCutoffs.addAll(list);
          if (list.length < batch) break;
          offset += batch;
        }
      }

      // ── 3. Collapse: best (highest) cutoff per canonical college + program ─
      final Map<String, _PrefItem> bestMap = {};

      for (final row in allCutoffs) {
        // Use canonical name for matching with college_details
        final canonicalName =
            (row['college_name_canonical'] as String? ??
                    row['college_name'] as String)
                .trim();
        final programName = (row['program_name'] as String).trim();
        final gender = (row['gender'] as String? ?? 'Co-Ed').trim();
        final cutoff = (row['cutoff_score'] as num).toDouble();

        if (cutoff <= 0) continue;

        // For Boys: skip Female colleges
        if (_selectedGenderUi == 'Boys' && gender == 'Female') continue;

        final details = collegeMap[canonicalName.toLowerCase()];

        // Campus filter
        if (_selectedCampus != 'Balanced') {
          final campusType = (details?['campus_type'] as String? ?? '')
              .toLowerCase();
          if (_selectedCampus == 'North Campus' &&
              !campusType.contains('north'))
            continue;
          if (_selectedCampus == 'South Campus' &&
              !campusType.contains('south'))
            continue;
        }

        final key = '${canonicalName.toLowerCase()}|||$programName';
        final existing = bestMap[key];

        // Keep highest cutoff (most competitive = most prestigious)
        if (existing == null || cutoff > existing.cutoffScore) {
          bestMap[key] = _PrefItem(
            collegeName: canonicalName,
            programName: programName,
            campus: details?['campus_type'] as String? ?? 'Off Campus',
            nirfRank: details?['nirf_ranking'] as int?,
            placementAvg: (details?['placement_avg'] as num?)?.toDouble(),
            placementHighest: (details?['placement_highest'] as num?)
                ?.toDouble(),
            cutoffScore: cutoff,
            naacGrade: details?['naac_grade'] as String?,
            score: 0,
          );
        }
      }

      // ── 4. Score ──────────────────────────────────────────────────────────
      final items = bestMap.values.toList();

      double nirfScore(int? rank) {
        if (rank == null || rank <= 0) return 0;
        return (101 - rank.clamp(1, 100)).toDouble();
      }

      double placementScore(double? avg) =>
          ((avg ?? 0) / 12.0 * 100).clamp(0.0, 100.0);

      double cutoffScore(double c) => (c / 800.0 * 100).clamp(0.0, 100.0);

      double naacBonus(String? g) {
        switch (g) {
          case 'A++':
            return 10;
          case 'A+':
            return 7;
          case 'A':
            return 4;
          default:
            return 0;
        }
      }

      double campusBonus(String campus) {
        if (_selectedCampus == 'Balanced') return 0;
        final c = campus.toLowerCase();
        if (_selectedCampus == 'North Campus' && c.contains('north')) return 15;
        if (_selectedCampus == 'South Campus' && c.contains('south')) return 15;
        return 0;
      }

      for (final item in items) {
        final nirf = nirfScore(item.nirfRank);
        final place = placementScore(item.placementAvg);
        final cut = cutoffScore(item.cutoffScore);
        final naac = naacBonus(item.naacGrade);
        final campus = campusBonus(item.campus);

        double base;
        switch (_selectedPriority) {
          case 'NIRF Ranking':
            base = nirf * 0.55 + place * 0.20 + cut * 0.15 + naac;
            break;
          case 'Placements':
            base = nirf * 0.15 + place * 0.60 + cut * 0.15 + naac;
            break;
          case 'Cutoffs':
            base = nirf * 0.15 + place * 0.15 + cut * 0.60 + naac;
            break;
          default: // Balanced
            base = nirf * 0.35 + place * 0.35 + cut * 0.20 + naac;
        }
        item.score = base + campus;
      }

      // ── 5. Sort ───────────────────────────────────────────────────────────
      items.sort((a, b) => b.score.compareTo(a.score));

      if (mounted) {
        setState(() {
          _generatedSheet = items;
          _isGenerating = false;
        });
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = 'Generation failed: $e\n$st';
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0E14)
          : const Color(0xFFF4F6FF),
      appBar: _buildAppBar(theme, isDark),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(isDark, theme),
            Expanded(child: _buildStepContent(theme, isDark)),
            if (_currentStep != 2) _buildBottomNav(theme),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF161C24) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preference Generator',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Text(
            'CSAS DU Admission Helper',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
          ),
        ],
      ),
      actions: [
        if (_currentStep == 2 && _generatedSheet.isNotEmpty)
          IconButton(
            tooltip: 'Restart',
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () => setState(() {
              _currentStep = 0;
              _generatedSheet = [];
              _selectedCourses.clear();
            }),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStepIndicator(bool isDark, ThemeData theme) {
    final steps = ['Courses', 'Preferences', 'Your Sheet'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      color: isDark ? const Color(0xFF161C24) : Colors.white,
      child: Row(
        children: List.generate(steps.length, (i) {
          final done = _currentStep > i;
          final active = _currentStep == i;
          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active
                        ? theme.colorScheme.primary
                        : done
                        ? Colors.green.shade500
                        : (isDark ? Colors.white10 : Colors.grey.shade100),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: active
                          ? theme.colorScheme.primary
                          : done
                          ? Colors.green.shade500
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: done
                      ? const Icon(
                          LucideIcons.check,
                          color: Colors.white,
                          size: 14,
                        )
                      : Text(
                          '${i + 1}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: active
                                ? Colors.white
                                : (isDark ? Colors.white38 : Colors.grey),
                          ),
                        ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    steps[i],
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? theme.colorScheme.primary
                          : (done ? Colors.green : Colors.grey),
                    ),
                  ),
                ),
                if (i < steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 13,
                      color: Colors.grey.shade400,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme, bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildCourseStep(theme, isDark);
      case 1:
        return _buildPreferencesStep(theme, isDark);
      case 2:
        return _buildResultsStep(theme, isDark);
      default:
        return const SizedBox();
    }
  }

  // ─── STEP 1: Course Selection ─────────────────────────────────────────────
  Widget _buildCourseStep(ThemeData theme, bool isDark) {
    if (_loadingCourses) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Loading all DU programs…',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _courseCategories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.wifiOff,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadCourseList,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final cats = _courseCategories.keys.toList();

    return DefaultTabController(
      length: cats.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Which programs are you targeting?',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select every program you want considered. More = richer results.',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                if (_selectedCourses.isNotEmpty)
                  Chip(
                    avatar: Icon(
                      LucideIcons.checkCircle2,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(
                      '${_selectedCourses.length} selected',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: theme.colorScheme.primary.withOpacity(
                      0.08,
                    ),
                    side: BorderSide.none,
                    deleteIcon: Icon(
                      LucideIcons.x,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    onDeleted: () => setState(() => _selectedCourses.clear()),
                  ),
              ],
            ),
          ),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
            tabs: cats.map((c) {
              final count = _courseCategories[c]!
                  .where((p) => _selectedCourses.contains(p))
                  .length;
              return Tab(text: count > 0 ? '$c ($count)' : c);
            }).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: cats.map((cat) {
                final courses = _courseCategories[cat]!;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: courses.length,
                  itemBuilder: (ctx, i) {
                    final course = courses[i];
                    final isSel = _selectedCourses.contains(course);
                    return _CourseCard(
                      course: course,
                      category: cat,
                      isSelected: isSel,
                      primaryColor: theme.colorScheme.primary,
                      isDark: isDark,
                      onToggle: (val) => setState(() {
                        if (val) {
                          _selectedCourses.add(course);
                        } else {
                          _selectedCourses.remove(course);
                        }
                      }),
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

  // ─── STEP 2: Preferences ─────────────────────────────────────────────────
  Widget _buildPreferencesStep(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personalise Your Ranking',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'These settings control the mathematical weights used to rank colleges.',
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 28),

          // Category — use correct labels mapping to DB values
          _PrefSection(
            icon: LucideIcons.users,
            title: 'Admission Category',
            subtitle: 'Cutoffs are fetched for this category',
            child: _ChipSelector(
              options: _categoryDbMap.keys.toList(),
              selected: _selectedCategoryUi,
              onSelect: (v) => setState(() => _selectedCategoryUi = v),
              primaryColor: theme.colorScheme.primary,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 20),

          // Gender
          _PrefSection(
            icon: LucideIcons.userCheck,
            title: 'Gender',
            subtitle:
                'Boys: Co-Ed colleges only  ·  Girls & All: includes Women\'s colleges',
            child: _ChipSelector(
              options: const ['All', 'Girls', 'Boys'],
              selected: _selectedGenderUi,
              onSelect: (v) => setState(() => _selectedGenderUi = v),
              primaryColor: theme.colorScheme.primary,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 20),

          // Campus
          _PrefSection(
            icon: LucideIcons.mapPin,
            title: 'Campus Preference',
            subtitle: 'Picks colleges from your preferred campus zone',
            child: _ChipSelector(
              options: const ['Balanced', 'North Campus', 'South Campus'],
              selected: _selectedCampus,
              onSelect: (v) => setState(() => _selectedCampus = v),
              primaryColor: theme.colorScheme.primary,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 20),

          // Priority
          _PrefSection(
            icon: LucideIcons.sliders,
            title: 'Primary Evaluation Metric',
            subtitle: 'The factor that carries the highest weight in scoring',
            child: Column(
              children: [
                _MetricTile(
                  title: 'Balanced  (Recommended)',
                  desc: 'NIRF 35% · Placements 35% · Cutoff 20% · NAAC 10%',
                  icon: LucideIcons.scale,
                  value: 'Balanced',
                  selected: _selectedPriority,
                  onTap: (v) => setState(() => _selectedPriority = v),
                  primary: theme.colorScheme.primary,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _MetricTile(
                  title: 'Best Placements',
                  desc: 'NIRF 15% · Placements 60% · Cutoff 15% · NAAC 10%',
                  icon: LucideIcons.banknote,
                  value: 'Placements',
                  selected: _selectedPriority,
                  onTap: (v) => setState(() => _selectedPriority = v),
                  primary: theme.colorScheme.primary,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _MetricTile(
                  title: 'NIRF / Academic Rank',
                  desc: 'NIRF 55% · Placements 20% · Cutoff 15% · NAAC 10%',
                  icon: LucideIcons.award,
                  value: 'NIRF Ranking',
                  selected: _selectedPriority,
                  onTap: (v) => setState(() => _selectedPriority = v),
                  primary: theme.colorScheme.primary,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _MetricTile(
                  title: 'Cutoff Prestige',
                  desc: 'NIRF 15% · Placements 15% · Cutoff 60% · NAAC 10%',
                  icon: LucideIcons.trendingUp,
                  value: 'Cutoffs',
                  selected: _selectedPriority,
                  onTap: (v) => setState(() => _selectedPriority = v),
                  primary: theme.colorScheme.primary,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── STEP 3: Results ──────────────────────────────────────────────────────
  Widget _buildResultsStep(ThemeData theme, bool isDark) {
    if (_isGenerating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Crunching the numbers…',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scoring ${_selectedCourses.length} programs across DU',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.alertCircle,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  _currentStep = 1;
                  _errorMessage = null;
                }),
                icon: const Icon(LucideIcons.arrowLeft, size: 16),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_generatedSheet.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.searchX, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 20),
              Text(
                'No Colleges Found',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'No DU colleges offer the selected programs for '
                '$_selectedCategoryUi category. Try a different category, '
                'gender filter, or add more courses.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.grey,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep = 0),
                icon: const Icon(LucideIcons.edit3, size: 16),
                label: const Text('Modify Selection'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: theme.colorScheme.primary.withOpacity(0.06),
          child: Row(
            children: [
              Icon(
                LucideIcons.info,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(fontSize: 12, height: 1.4),
                    children: [
                      TextSpan(
                        text: '${_generatedSheet.length} combinations  ·  ',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text:
                            '$_selectedCategoryUi · $_selectedCampus · $_selectedPriority',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.amber.withOpacity(0.06),
          child: Row(
            children: [
              Icon(
                LucideIcons.gripVertical,
                size: 14,
                color: Colors.amber.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hold & drag any card to reorder manually before saving.',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: _generatedSheet.length,
            onReorder: (oldIdx, newIdx) {
              setState(() {
                if (newIdx > oldIdx) newIdx--;
                final item = _generatedSheet.removeAt(oldIdx);
                _generatedSheet.insert(newIdx, item);
              });
            },
            itemBuilder: (ctx, idx) {
              final item = _generatedSheet[idx];
              return _ResultCard(
                key: ValueKey('${item.collegeName}|||${item.programName}'),
                item: item,
                rank: idx + 1,
                primaryColor: theme.colorScheme.primary,
                isDark: isDark,
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          color: theme.cardColor,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportToClipboard,
                  icon: const Icon(LucideIcons.copy, size: 16),
                  label: const Text('Copy List'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _savePreferenceSheet,
                  icon: const Icon(LucideIcons.checkCircle, size: 16),
                  label: const Text('Save & Submit'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
    final isStep0Empty = _currentStep == 0 && _selectedCourses.isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep--),
              icon: const Icon(LucideIcons.arrowLeft, size: 16),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            )
          else
            const SizedBox(),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: isStep0Empty ? null : _handleNext,
            icon: Icon(
              _currentStep == 1 ? LucideIcons.sparkles : LucideIcons.arrowRight,
              size: 16,
            ),
            label: Text(_currentStep == 1 ? 'Generate Sheet' : 'Continue'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    if (_currentStep == 1) {
      _generatePreferences();
    } else {
      setState(() => _currentStep++);
    }
  }

  void _exportToClipboard() {
    final buf = StringBuffer();
    buf.writeln('🎓 DU CSAS Preference Sheet');
    buf.writeln(
      'Category: $_selectedCategoryUi  |  Campus: $_selectedCampus  |  Priority: $_selectedPriority',
    );
    buf.writeln('─' * 60);
    for (int i = 0; i < _generatedSheet.length; i++) {
      final it = _generatedSheet[i];
      buf.writeln(
        '${i + 1}. ${it.collegeName} — ${it.programName}  [${it.campus}]',
      );
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ Preference sheet copied to clipboard!',
          style: GoogleFonts.outfit(),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _savePreferenceSheet() async {
    final prefService = Provider.of<DuPreferenceService>(
      context,
      listen: false,
    );
    final authService = Provider.of<AuthService>(context, listen: false);

    final user = authService.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? 'Student';
    final userEmail = user?.email ?? '';

    final sheetData = _generatedSheet
        .asMap()
        .entries
        .map(
          (e) => {
            'collegeName': e.value.collegeName,
            'programName': e.value.programName,
            'rank': e.key + 1,
          },
        )
        .toList();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    final saved = await prefService.savePreferenceSheet(
      userName: userName,
      userEmail: userEmail,
      targetCourses: _selectedCourses.toList(),
      campusPreference: _selectedCampus,
      priorityFactor: _selectedPriority,
      sheetData: sheetData,
    );

    if (mounted) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(
                saved ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                color: saved ? Colors.green : Colors.amber,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  saved ? 'Sheet Saved!' : 'Saved Locally',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            saved
                ? 'Your preference sheet has been saved to the server and admin dashboard.'
                : 'Saved in local cache. Will sync when connectivity is restored.',
            style: GoogleFonts.outfit(height: 1.5),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _CourseCard extends StatelessWidget {
  final String course, category;
  final bool isSelected, isDark;
  final Color primaryColor;
  final void Function(bool) onToggle;

  const _CourseCard({
    required this.course,
    required this.category,
    required this.isSelected,
    required this.primaryColor,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor.withOpacity(0.07)
            : (isDark ? const Color(0xFF1A2233) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? primaryColor
              : (isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.grey.shade200),
          width: isSelected ? 1.8 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onToggle(!isSelected),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          LucideIcons.check,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course,
                        style: GoogleFonts.outfit(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 14,
                          color: isSelected ? primaryColor : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrefSection extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Widget child;

  const _PrefSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _ChipSelector extends StatelessWidget {
  final List<String> options;
  final String selected;
  final void Function(String) onSelect;
  final Color primaryColor;
  final bool isDark;

  const _ChipSelector({
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSel = selected == opt;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isSel
                  ? primaryColor
                  : (isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isSel
                    ? primaryColor
                    : (isDark ? Colors.white12 : Colors.grey.shade300),
              ),
            ),
            child: Text(
              opt,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                color: isSel
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title, desc, value, selected;
  final IconData icon;
  final Color primary;
  final bool isDark;
  final void Function(String) onTap;

  const _MetricTile({
    required this.title,
    required this.desc,
    required this.icon,
    required this.value,
    required this.selected,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSel = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSel
              ? primary.withOpacity(0.07)
              : (isDark ? const Color(0xFF1A2233) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel
                ? primary
                : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.shade200),
            width: isSel ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSel
                    ? primary.withOpacity(0.12)
                    : Colors.grey.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: isSel ? primary : Colors.grey),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isSel ? primary : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSel) Icon(LucideIcons.checkCircle2, color: primary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final _PrefItem item;
  final int rank;
  final Color primaryColor;
  final bool isDark;

  const _ResultCard({
    required super.key,
    required this.item,
    required this.rank,
    required this.primaryColor,
    required this.isDark,
  });

  Color _rankColor() {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return primaryColor.withOpacity(0.15);
  }

  Color _rankTextColor() => rank <= 3 ? Colors.white : primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2233) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank <= 3
              ? _rankColor().withOpacity(0.5)
              : (isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.grey.shade200),
          width: rank <= 3 ? 1.5 : 1,
        ),
        boxShadow: rank <= 3
            ? [
                BoxShadow(
                  color: _rankColor().withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _rankColor(),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                style: GoogleFonts.outfit(
                  color: _rankTextColor(),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.collegeName,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.programName,
                    style: GoogleFonts.outfit(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (item.nirfRank != null && item.nirfRank! > 0)
                        _Tag(
                          icon: LucideIcons.award,
                          label: '#${item.nirfRank}',
                          color: Colors.amber.shade700,
                        ),
                      if (item.cutoffScore > 0)
                        _Tag(
                          icon: LucideIcons.trendingUp,
                          label: item.cutoffScore.toStringAsFixed(0),
                          color: Colors.blue.shade600,
                        ),
                      if (item.placementAvg != null && item.placementAvg! > 0)
                        _Tag(
                          icon: LucideIcons.banknote,
                          label: '${item.placementAvg!.toStringAsFixed(1)} LPA',
                          color: Colors.green.shade600,
                        ),
                      _Tag(
                        icon: LucideIcons.mapPin,
                        label: item.campus,
                        color: Colors.grey.shade600,
                      ),
                      if (item.naacGrade != null)
                        _Tag(
                          icon: LucideIcons.star,
                          label: 'NAAC ${item.naacGrade}',
                          color: Colors.purple.shade500,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              LucideIcons.gripVertical,
              color: Colors.grey.shade400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Tag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
