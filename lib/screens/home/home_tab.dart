import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/user_score_provider.dart';
import '../../providers/cutoff_provider.dart';
import '../prediction/prediction_results_screen.dart';
import '../analytics/analytics_tab.dart';
import '../wishlist/wishlist_tab.dart';
import '../timeline/csas_timeline_screen.dart';
import '../notifications/notification_screen.dart';
import '../counselling/counselling_guide_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _langController    = TextEditingController();
  final _domainController  = TextEditingController();
  final _domain2Controller = TextEditingController();
  final _domain3Controller = TextEditingController();

  bool _showExtraScores = false;

  @override
  void dispose() {
    _langController.dispose();
    _domainController.dispose();
    _domain2Controller.dispose();
    _domain3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme         = Theme.of(context);
    final scoreProvider = Provider.of<UserScoreProvider>(context);
    final cutoffProvider = Provider.of<CutoffProvider>(context);

    final allSubjects = DomainProgramMapping.allSubjects;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, Student 👋',
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.displayLarge?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Find your dream DU college',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: theme.textTheme.bodyLarge?.color
                                ?.withOpacity(0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.bell),
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationScreen())),
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Score Card ──────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(LucideIcons.calculator,
                              color: theme.colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Enter Your CUET Scores',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scores are out of 200 each. Composite = Language + Domain(s)',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 24),

                    // ── Language score ─────────────────────────────────
                    _buildInputLabel('Language (English / Hindi)',
                        LucideIcons.bookOpen, theme),
                    const SizedBox(height: 8),
                    _buildScoreField(
                      controller: _langController,
                      hint: '0 – 200',
                      onChanged: (v) => scoreProvider
                          .updateLanguageScore(double.tryParse(v) ?? 0),
                    ),
                    const SizedBox(height: 20),

                    // ── Domain Subject ─────────────────────────────────
                    _buildInputLabel('Domain Subject (Primary)',
                        LucideIcons.layers, theme),
                    const SizedBox(height: 8),
                    cutoffProvider.isLoading
                        ? Center(
                            child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary),
                          ))
                        : _buildSubjectDropdown(
                            context,
                            allSubjects,
                            scoreProvider.score.domainSubject,
                            scoreProvider.updateDomainSubject,
                            theme,
                          ),
                    const SizedBox(height: 12),
                    _buildScoreField(
                      controller: _domainController,
                      hint: 'Score in above subject (0 – 200)',
                      onChanged: (v) => scoreProvider
                          .updateDomainScore(double.tryParse(v) ?? 0),
                    ),
                    const SizedBox(height: 20),

                    // ── Optional extra domain scores ───────────────────
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showExtraScores = !_showExtraScores),
                      child: Row(
                        children: [
                          Icon(
                            _showExtraScores
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _showExtraScores
                                ? 'Hide additional domain scores'
                                : 'Add more domain scores (optional)',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_showExtraScores) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Domain 2 Score',
                        style: GoogleFonts.outfit(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      _buildScoreField(
                        controller: _domain2Controller,
                        hint: '0 – 200',
                        onChanged: (v) => scoreProvider
                            .updateDomain2Score(double.tryParse(v) ?? 0),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Domain 3 Score',
                        style: GoogleFonts.outfit(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      _buildScoreField(
                        controller: _domain3Controller,
                        hint: '0 – 200',
                        onChanged: (v) => scoreProvider
                            .updateDomain3Score(double.tryParse(v) ?? 0),
                      ),
                    ],

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 20),

                    // ── Category + PwD ─────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            context,
                            'Category',
                            scoreProvider.score.category,
                            ['General', 'OBC', 'SC', 'ST', 'EWS'],
                            (val) {
                              if (val != null) scoreProvider.updateCategory(val);
                            },
                            theme,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            context,
                            'PwD Quota',
                            'No',
                            ['No', 'Yes'],
                            (val) {
                              if (val == 'Yes') scoreProvider.updateCategory('PwD');
                            },
                            theme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Score Preview Chip ──────────────────────────────
                    _buildScorePreview(scoreProvider, theme),
                    const SizedBox(height: 24),

                    // ── CTA ────────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PredictionResultsScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(LucideIcons.search, size: 18),
                        label: Text(
                          'Predict My Colleges',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Counselling Guide Banner ────────────────────────────────
              InkWell(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const CounsellingGuideScreen())),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.85),
                        theme.colorScheme.primary
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.graduationCap,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DU CSAS Guide 2025',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold)),
                            Text('Complete roadmap for admissions',
                                style: GoogleFonts.outfit(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, color: Colors.white),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Quick Actions ───────────────────────────────────────────
              Text('Quick Actions',
                  style: GoogleFonts.outfit(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildQuickAction(context, LucideIcons.building, 'Colleges',
                      Colors.blue, onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PredictionResultsScreen()));
                  }),
                  const SizedBox(width: 8),
                  _buildQuickAction(context, LucideIcons.bookOpen, 'Cutoffs',
                      Colors.green, onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AnalyticsTab()));
                  }),
                  const SizedBox(width: 8),
                  _buildQuickAction(context, LucideIcons.calendar, 'Timeline',
                      Colors.orange, onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CsasTimelineScreen()));
                  }),
                  const SizedBox(width: 8),
                  _buildQuickAction(context, LucideIcons.heart, 'Wishlist',
                      Colors.red, onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WishlistTab()));
                  }),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Builders ─────────────────────────────────────────────────────────────

  Widget _buildInputLabel(String label, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreField({
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
      ),
      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
    );
  }

  Widget _buildSubjectDropdown(
    BuildContext context,
    List<String> subjects,
    String selected,
    Function(String) onChanged,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: subjects.contains(selected) ? selected : subjects.first,
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown),
          items: subjects
              .map((s) => DropdownMenuItem<String>(
                    value: s,
                    child: Text(s,
                        style: GoogleFonts.outfit(fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              icon: const Icon(LucideIcons.chevronDown, size: 16),
              items: items
                  .map((item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item, style: GoogleFonts.outfit(fontSize: 13)),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScorePreview(UserScoreProvider sp, ThemeData theme) {
    final total = sp.score.getTotalScore(false);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.zap, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Composite Score',
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: Colors.grey.shade500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${total.toStringAsFixed(0)} / 800',
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              sp.score.domainSubject,
              style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      BuildContext context, IconData icon, String label, Color color,
      {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                  fontSize: 11, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
