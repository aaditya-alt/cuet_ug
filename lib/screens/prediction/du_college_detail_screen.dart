import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/du_models.dart';
import '../../providers/du_predictor_service.dart';
import '../../providers/du_wishlist_provider.dart';
import '../../data/mock_data.dart';
import '../../models/college_model.dart';
import '../../providers/compare_provider.dart';
import '../compare/compare_screen.dart';

class DuCollegeDetailScreen extends StatefulWidget {
  final DuCollegeData college;
  final String category;
  final int year;

  const DuCollegeDetailScreen({
    Key? key,
    required this.college,
    required this.category,
    required this.year,
  }) : super(key: key);

  @override
  State<DuCollegeDetailScreen> createState() => _DuCollegeDetailScreenState();
}

class _DuCollegeDetailScreenState extends State<DuCollegeDetailScreen>
    with SingleTickerProviderStateMixin {
  final DuPredictorService _service = DuPredictorService();
  late AnimationController _animController;

  List<DuCollegeCourse> _courses = [];
  List<Map<String, dynamic>> _cutoffHistory = [];
  bool _isLoadingData = true;

  late String _viewerCategory;
  late int _viewerRound;

  @override
  void initState() {
    super.initState();
    _viewerCategory = widget.category;
    _viewerRound = 1;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fetchAdditionalData();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _shareCollege() async {
    final c = widget.college;
    final programs = c.programs.isNotEmpty
        ? c.programs
              .take(3)
              .map((p) =>
                  '• ${p.programName} — Cutoff: ${p.cutoffScore.toInt()} (${p.chance})')
              .join('\n')
        : 'Multiple programs available';

    final shareUrl = 'https://cuet.collegemitra.net.in/college?name=${Uri.encodeComponent(c.collegeName)}';

    final text = '''
🎓 ${c.collegeName}
📍 ${c.campusType ?? 'Delhi University'} | Est. ${c.established ?? 'N/A'}
${c.naacGrade != null ? '🏆 NAAC ${c.naacGrade}' : ''}${c.nirfRanking != null ? ' | NIRF #${c.nirfRanking}' : ''}

📚 Eligible Programs (Category: ${widget.category}):
$programs

🔗 Check your chances at this college:
$shareUrl

✨ Predict your dream DU college with 99% accuracy!
Download DU Cutoff Predictor 2025 — completely FREE!
https://cuet.collegemitra.net.in'''.trim();

    await Share.share(text, subject: 'Check out ${c.collegeName} on DU Predictor!');
  }

  Future<void> _fetchAdditionalData() async {
    try {
      final courses = await _service.getCollegeCourses(
        widget.college.collegeName,
      );
      final history = await _service.getCutoffHistory(
        widget.college.collegeName,
      );
      setState(() {
        _courses = courses;
        _cutoffHistory = history;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Glassmorphism Header ──
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            stretch: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: IconButton(
                      icon: const Icon(
                        LucideIcons.chevronLeft,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              Consumer<DuWishlistProvider>(
                builder: (ctx, wishlist, _) {
                  final saved = wishlist.isWishlisted(widget.college.collegeName);
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: Colors.black.withOpacity(0.3),
                          child: IconButton(
                            icon: Icon(
                              LucideIcons.heart,
                              color: saved ? Colors.red : Colors.white,
                            ),
                            onPressed: () {
                              wishlist.toggle(widget.college);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(saved
                                      ? 'Removed from wishlist'
                                      : 'Saved to wishlist ❤️'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Builder(
                builder: (context) {
                  CollegeModel? resolvedModel;
                  try {
                    resolvedModel = MockData.colleges.firstWhere(
                      (c) => c.name.toLowerCase() == widget.college.collegeName.toLowerCase(),
                    );
                  } catch (_) {}

                  if (resolvedModel == null) return const SizedBox.shrink();

                  return Consumer<CompareProvider>(
                    builder: (ctx, compareProvider, _) {
                      final inCompare = compareProvider.isInCompare(resolvedModel!.id);
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              color: Colors.black.withOpacity(0.3),
                              child: IconButton(
                                icon: Icon(
                                  LucideIcons.gitCompare,
                                  color: inCompare ? Colors.greenAccent : Colors.white,
                                ),
                                onPressed: () {
                                  final added = compareProvider.toggleCompare(resolvedModel!);
                                  if (!added && !compareProvider.isInCompare(resolvedModel!.id) && compareProvider.count >= 2) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Comparison list is full! Max 2 colleges can be compared.'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(added ? 'Added to compare list 📋' : 'Removed from compare list'),
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: IconButton(
                        icon: const Icon(LucideIcons.share2, color: Colors.white),
                        onPressed: _shareCollege,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Main Image with Parallax-like effect (via stretch)
                  Hero(
                    tag: 'image_${widget.college.id}',
                    child: CachedNetworkImage(
                      imageUrl:
                          widget.college.mainImageUrl ??
                          'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?q=80&w=1000',
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.2),
                              theme.colorScheme.secondary.withOpacity(0.2),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Enhanced Gradient Overlays
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.4, 0.7, 1.0],
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),

                  // College Info Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.college.naacGrade != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'NAAC ${widget.college.naacGrade}',
                                style: GoogleFonts.outfit(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.college.collegeName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          LucideIcons.mapPin,
                                          size: 14,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          widget.college.campusType ??
                                              'Delhi University',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (widget.college.established !=
                                            null) ...[
                                          const SizedBox(width: 12),
                                          const Icon(
                                            LucideIcons.calendar,
                                            size: 14,
                                            color: Colors.white70,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Est. ${widget.college.established}',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white70,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.college.logoUrl != null)
                                Hero(
                                  tag: 'logo_${widget.college.id}',
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Image.network(
                                      widget.college.logoUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _animController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Key Stats Row ──
                    Row(
                      children: [
                        _buildPremiumStatCard(
                          'NIRF Rank',
                          '#${widget.college.nirfRanking ?? 'N/A'}',
                          LucideIcons.trophy,
                          Colors.amber,
                          isDark,
                        ),
                        const SizedBox(width: 12),
                        _buildPremiumStatCard(
                          'Avg Package',
                          '${widget.college.placementAvg ?? '6.5'} LPA',
                          LucideIcons.trendingUp,
                          Colors.blue,
                          isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── About Section ──
                    _buildSectionHeader('About', LucideIcons.info, theme),
                    Text(
                      widget.college.description ??
                          'No description available for this college.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Notable Alumni ──
                    if (widget.college.notableAlumni != null &&
                        widget.college.notableAlumni!.isNotEmpty) ...[
                      _buildSectionHeader(
                        'Notable Alumni',
                        LucideIcons.users,
                        theme,
                      ),
                      _buildAlumniList(isDark),
                      const SizedBox(height: 32),
                    ],

                    // ── Placement Highlights ──
                    _buildSectionHeader(
                      'Placement Statistics',
                      LucideIcons.barChart3,
                      theme,
                    ),
                    _buildPlacementGrid(isDark),
                    const SizedBox(height: 32),

                    // ── Cutoff History (Premium Design) ──
                    _buildSectionHeader(
                      'Admission History',
                      LucideIcons.history,
                      theme,
                    ),
                    _buildPremiumCutoffViewer(theme, isDark),
                    const SizedBox(height: 32),

                    // ── Courses & Fee ──
                    _buildSectionHeader(
                      'Available Programs',
                      LucideIcons.bookOpen,
                      theme,
                    ),
                    _buildCoursesList(theme, isDark),
                    const SizedBox(height: 32),

                    // ── Facilities ──
                    if (widget.college.facilities.isNotEmpty) ...[
                      _buildSectionHeader(
                        'Campus Facilities',
                        LucideIcons.sparkles,
                        theme,
                      ),
                      _buildFacilitiesWrap(theme, isDark),
                      const SizedBox(height: 32),
                    ],

                    // ── Contact & Location ──
                    _buildSectionHeader(
                      'Location & Contact',
                      LucideIcons.map,
                      theme,
                    ),
                    _buildContactCard(isDark, theme),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.1),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: color.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacementGrid(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPlacementItem(
              'Highest',
              '${widget.college.placementHighest ?? '18'} LPA',
              Colors.blue,
            ),
            _buildVerticalDivider(isDark),
            _buildPlacementItem(
              'Average',
              '${widget.college.placementAvg ?? '6.5'} LPA',
              Colors.indigo,
            ),
            _buildVerticalDivider(isDark),
            _buildPlacementItem(
              'Placed %',
              '${widget.college.placementPercent ?? '85'}%',
              const Color(0xFF10B981),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacementItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(bool isDark) => Container(
    height: 40,
    width: 1,
    color: isDark ? Colors.white10 : Colors.grey.shade300,
  );

  Widget _buildPremiumCutoffViewer(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStyledDropdown<String>(
                  label: 'Category',
                  value: _viewerCategory,
                  items: ['UR', 'OBC', 'SC', 'ST', 'EWS', 'PwBD'],
                  onChanged: (v) => setState(() => _viewerCategory = v!),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStyledDropdown<int>(
                  label: 'Round',
                  value: _viewerRound,
                  items: [1, 3],
                  onChanged: (v) => setState(() => _viewerRound = v!),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoadingData)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else
            _buildCutoffRows(isDark),
        ],
      ),
    );
  }

  Widget _buildStyledDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required Function(T?) onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: const Icon(LucideIcons.chevronDown, size: 14),
              items: items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e.toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCutoffRows(bool isDark) {
    final filtered = _cutoffHistory
        .where(
          (c) => c['category'] == _viewerCategory && c['round'] == _viewerRound,
        )
        .toList();
    if (filtered.isEmpty)
      return Text(
        'No history found.',
        style: GoogleFonts.outfit(color: Colors.grey),
      );

    return Column(
      children: filtered.map((c) {
        final score = (c['cutoff_score'] as num).toInt();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  c['program_name'],
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                score.toString(),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCoursesList(ThemeData theme, bool isDark) {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade200,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.graduationCap,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.courseName,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          course.duration ?? '3 Years',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    course.fees ?? '₹15,000',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'per year',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFacilitiesWrap(ThemeData theme, bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.college.facilities
          .map(
            (f) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.shade200,
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getFacilityIcon(f),
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    f,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: isDark
                          ? Colors.grey.shade300
                          : Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  IconData _getFacilityIcon(String facility) {
    facility = facility.toLowerCase();
    if (facility.contains('wifi')) return LucideIcons.wifi;
    if (facility.contains('library')) return LucideIcons.book;
    if (facility.contains('gym')) return LucideIcons.dumbbell;
    if (facility.contains('hostel')) return LucideIcons.home;
    if (facility.contains('cafeteria') || facility.contains('canteen'))
      return LucideIcons.coffee;
    if (facility.contains('sports')) return LucideIcons.trophy;
    if (facility.contains('lab')) return LucideIcons.beaker;
    if (facility.contains('medical')) return LucideIcons.heartPulse;
    return LucideIcons.checkCircle2;
  }

  Widget _buildContactCard(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          _buildContactItem(
            LucideIcons.mapPin,
            'Address',
            widget.college.address ?? 'Delhi, India',
            isDark,
          ),
          const Divider(height: 32),
          _buildContactItem(
            LucideIcons.train,
            'Nearest Metro',
            widget.college.nearestMetro ?? 'N/A',
            isDark,
          ),
          const Divider(height: 32),
          _buildContactItem(
            LucideIcons.globe,
            'Website',
            widget.college.website ?? 'www.du.ac.in',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildAlumniList(bool isDark) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.college.notableAlumni!.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final person = widget.college.notableAlumni![index];
          String name = '';
          String? field;
          String? imageUrl;

          if (person is String) {
            name = person;
          } else if (person is Map) {
            name = person['name'] ?? '';
            field = person['field'];
            imageUrl = person['image_url'];
          }

          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  backgroundImage: imageUrl != null
                      ? NetworkImage(imageUrl)
                      : null,
                  child: imageUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0] : '?',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (field != null)
                        Text(
                          field,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
