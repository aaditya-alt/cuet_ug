import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../data/mock_data.dart';
import '../college/college_details_screen.dart';
import '../../providers/user_score_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/cutoff_provider.dart';
import '../../providers/compare_provider.dart';
import '../../models/college_model.dart';
import '../compare/compare_screen.dart';

class PredictionResultsScreen extends StatefulWidget {
  const PredictionResultsScreen({super.key});

  @override
  State<PredictionResultsScreen> createState() =>
      _PredictionResultsScreenState();
}

class _PredictionResultsScreenState extends State<PredictionResultsScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _chanceFilter {
    switch (_tabController.index) {
      case 1: return 'High';
      case 2: return 'Medium';
      case 3: return 'Low';
      default: return 'All';
    }
  }

  // ── Build a CollegeModel from real JSON data (fallback when not in MockData) ──
  CollegeModel _resolveCollege(
      String collegeName, CutoffProvider cutoffProvider) {
    // 1) Try exact match in MockData
    try {
      return MockData.colleges
          .firstWhere((c) => c.name.toLowerCase() == collegeName.toLowerCase());
    } catch (_) {}

    // 2) Try contains match
    try {
      return MockData.colleges.firstWhere((c) =>
          c.name.toLowerCase().contains(collegeName.toLowerCase()) ||
          collegeName.toLowerCase().contains(c.name.toLowerCase()));
    } catch (_) {}

    // 3) Build a minimal CollegeModel from real cutoff data
    final programs = cutoffProvider.getProgramsForCollege(collegeName);
    final courses = programs.map((p) {
      return CourseCutoff(
        courseName: p,
        cutoffs: {
          'General': CategoryCutoff(round1: 0, round2: 0, round3: 0, expected2026: 0),
          'OBC':     CategoryCutoff(round1: 0, round2: 0, round3: 0, expected2026: 0),
          'SC':      CategoryCutoff(round1: 0, round2: 0, round3: 0, expected2026: 0),
          'ST':      CategoryCutoff(round1: 0, round2: 0, round3: 0, expected2026: 0),
          'EWS':     CategoryCutoff(round1: 0, round2: 0, round3: 0, expected2026: 0),
        },
        fee: 'As per DU norms',
        duration: '3 Years',
      );
    }).toList();

    return CollegeModel(
      id: collegeName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_'),
      name: collegeName,
      campus: _inferCampus(collegeName),
      type: 'Government',
      gender: _inferGender(collegeName),
      logoUrl:
          'https://upload.wikimedia.org/wikipedia/en/4/41/DU_logo.png',
      photos: const [],
      nirfRanking: 999,
      courses: courses.isNotEmpty
          ? courses
          : [
              CourseCutoff(
                courseName: 'Various Programs',
                cutoffs: {},
                fee: 'As per DU norms',
                duration: '3 Years',
              )
            ],
      description:
          'A constituent college of the University of Delhi offering quality education.',
      address: 'University of Delhi, Delhi',
      nearbyMetro: 'Contact college for directions',
      rankings: const [],
      facilities: const [],
    );
  }

  String _inferCampus(String name) {
    final n = name.toLowerCase();
    if (n.contains('north') ||
        n.contains('miranda') ||
        n.contains('hindu') ||
        n.contains('ramjas') ||
        n.contains('stephen') ||
        n.contains('srcc') ||
        n.contains('hansraj') ||
        n.contains('kirori') ||
        n.contains('daulat') ||
        n.contains('indraprastha') ||
        n.contains('khalsa')) return 'North Campus';
    if (n.contains('south') ||
        n.contains('lady shri ram') ||
        n.contains('lsr') ||
        n.contains('venkat') ||
        n.contains('gargi') ||
        n.contains('kamla') ||
        n.contains('maitreyi') ||
        n.contains('motilal') ||
        n.contains('shaheed bhagat') ||
        n.contains('arsd') ||
        n.contains('jesus') ||
        n.contains('pgdav')) return 'South Campus';
    return 'Off Campus';
  }

  String _inferGender(String name) {
    final n = name.toLowerCase();
    if (n.contains('(w)') ||
        n.contains('women') ||
        n.contains('girls') ||
        n.contains('mahavidyalaya')) return 'Women';
    return 'Co-ed';
  }

  @override
  Widget build(BuildContext context) {
    final scoreProvider    = Provider.of<UserScoreProvider>(context);
    final cutoffProvider   = Provider.of<CutoffProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final compareProvider  = Provider.of<CompareProvider>(context);
    final theme = Theme.of(context);

    final userScore     = scoreProvider.score.getTotalScore(false);
    final category      = scoreProvider.score.category;
    final domainSubject = scoreProvider.score.domainSubject;

    // Build predictions from real data
    List<PredictionResult> predictions = [];
    if (!cutoffProvider.isLoading) {
      predictions = cutoffProvider.getPredictionsForStudent(
        userScore: userScore,
        category: category,
        domainSubject: domainSubject,
      );
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      predictions = predictions
          .where((p) =>
              p.collegeName.toLowerCase().contains(q) ||
              p.programName.toLowerCase().contains(q))
          .toList();
    }

    // Apply chance tab filter
    if (_chanceFilter != 'All') {
      predictions =
          predictions.where((p) => p.chance == _chanceFilter).toList();
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('College Predictions',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          labelStyle:
              GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: '✅ High'),
            Tab(text: '⚡ Medium'),
            Tab(text: '❌ Low'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Info banner ───────────────────────────────────────────────
          Container(
            color: theme.colorScheme.primary.withOpacity(0.06),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(LucideIcons.info,
                    size: 13, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Score: ${userScore.toStringAsFixed(0)} / 800  •  $domainSubject  •  $category',
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // ── Search bar ────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                hintText: 'Search college or program…',
                hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: GoogleFonts.outfit(fontSize: 14),
            ),
          ),

          // ── Result count ──────────────────────────────────────────────
          if (!cutoffProvider.isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${predictions.length} result${predictions.length == 1 ? '' : 's'}',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            ),

          // ── Results list ──────────────────────────────────────────────
          Expanded(
            child: cutoffProvider.isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                            color: theme.colorScheme.primary),
                        const SizedBox(height: 16),
                        Text('Loading 2025 cutoff data…',
                            style:
                                GoogleFonts.outfit(color: Colors.grey)),
                      ],
                    ),
                  )
                : predictions.isEmpty
                    ? _buildEmpty(context)
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          MediaQuery.of(context).viewInsets.bottom + 100,
                        ),
                        itemCount: predictions.length,
                        itemBuilder: (context, index) {
                          final p = predictions[index];
                          final college =
                              _resolveCollege(p.collegeName, cutoffProvider);
                          final isInCompare =
                              compareProvider.isInCompare(college.id);
                          return _buildCard(
                            context,
                            p,
                            college,
                            isInCompare,
                            wishlistProvider,
                            compareProvider,
                            theme,
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: compareProvider.count == 2
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompareScreen(
                    college1: compareProvider.compareList[0],
                    college2: compareProvider.compareList[1],
                  ),
                ),
              ),
              backgroundColor: Colors.orange,
              icon: const Icon(LucideIcons.arrowLeftRight,
                  color: Colors.white),
              label: Text('Compare Now',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            )
          : null,
    );
  }

  // ── Card ──────────────────────────────────────────────────────────────────
  Widget _buildCard(
    BuildContext context,
    PredictionResult p,
    CollegeModel college,
    bool isInCompare,
    WishlistProvider wishlistProvider,
    CompareProvider compareProvider,
    ThemeData theme,
  ) {
    final chanceColor = p.chance == 'High'
        ? Colors.green
        : p.chance == 'Medium'
            ? Colors.orange
            : Colors.red;

    final chanceIcon = p.chance == 'High'
        ? LucideIcons.checkCircle2
        : p.chance == 'Medium'
            ? LucideIcons.alertCircle
            : LucideIcons.xCircle;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CollegeDetailsScreen(college: college)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Logo + name + actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        college.logoUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                            LucideIcons.building2,
                            color: Colors.grey,
                            size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // College + program name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.collegeName,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p.programName,
                          style: GoogleFonts.outfit(
                              fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Wishlist + compare
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          final was = wishlistProvider
                              .isInWishlist(college.id);
                          wishlistProvider.toggleWishlist(college);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(was
                                  ? '${college.name} removed'
                                  : '${college.name} added to wishlist'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            LucideIcons.heart,
                            size: 18,
                            color: wishlistProvider.isInWishlist(college.id)
                                ? Colors.red
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (!isInCompare && compareProvider.count >= 2) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'You can only compare 2 colleges at a time.')),
                            );
                            return;
                          }
                          compareProvider.toggleCompare(college);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isInCompare
                                ? LucideIcons.checkCircle2
                                : LucideIcons.plusCircle,
                            size: 17,
                            color: isInCompare
                                ? Colors.orange
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Row 2: Cutoff | Your Score | Chance badge
              Row(
                children: [
                  // Round 1 cutoff
                  _buildMetric(
                    'Round 1 Cutoff 2025',
                    p.cutoffScore.toStringAsFixed(0),
                    LucideIcons.shieldCheck,
                    Colors.green,
                  ),
                  const SizedBox(width: 16),
                  // Your score
                  _buildMetric(
                    'Your Score',
                    p.userScore.toStringAsFixed(0),
                    LucideIcons.user,
                    Theme.of(context).colorScheme.primary,
                  ),
                  const Spacer(),
                  // Chance badge
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: chanceColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: chanceColor.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(chanceIcon, size: 13, color: chanceColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${p.chance} Chance',
                              style: GoogleFonts.outfit(
                                color: chanceColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(
      String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 9, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.searchX,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No matching colleges found',
                style: GoogleFonts.outfit(
                    fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different domain subject\nor adjusting your score on the home screen.',
              style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(LucideIcons.arrowLeft),
              label: const Text('Go Back & Adjust'),
            ),
          ],
        ),
      ),
    );
  }
}
