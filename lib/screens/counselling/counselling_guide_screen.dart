import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CounsellingGuideScreen extends StatefulWidget {
  const CounsellingGuideScreen({super.key});

  @override
  State<CounsellingGuideScreen> createState() => _CounsellingGuideScreenState();
}

class _CounsellingGuideScreenState extends State<CounsellingGuideScreen> {
  List<Map<String, dynamic>> _dynamicSteps = [];
  bool _isLoading = false;

  final List<Color> _stepColors = [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.teal,
    Colors.red,
  ];

  @override
  void initState() {
    super.initState();
    _fetchDynamicGuides();
  }

  Future<void> _fetchDynamicGuides() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('updates')
          .select()
          .eq('category', 'CSAS Guide')
          .order('id', ascending: true);

      if (response != null && response is List && response.isNotEmpty) {
        if (mounted) {
          setState(() {
            _dynamicSteps = List<Map<String, dynamic>>.from(response);
          });
        }
      }
    } catch (e) {
      debugPrint('Dynamic guides fetch error: $e');
      // If table is missing or empty, it will fall back to offline guide items
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text('Counselling Guide'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: _fetchDynamicGuides,
            tooltip: 'Refresh Guide',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDynamicGuides,
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildHeroCard(theme),
                  const SizedBox(height: 32),
                  _buildSectionTitle('The CSAS Process', theme),
                  const SizedBox(height: 16),
                  
                  // Render dynamic guide steps if available, else static steps
                  if (_dynamicSteps.isNotEmpty)
                    ..._dynamicSteps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value;
                      final stepNum = (index + 1).toString().padLeft(2, '0');
                      final color = _stepColors[index % _stepColors.length];
                      return _buildGuideStep(
                        step: stepNum,
                        title: step['title'] ?? 'Guide Step',
                        description: step['content'] ?? '',
                        color: color,
                      );
                    })
                  else ...[
                    _buildGuideStep(
                      step: '01',
                      title: 'Phase I: Registration',
                      description: 'Fill the common application form on the DU portal. You need to provide your CUET application number and personal details.',
                      color: Colors.blue,
                    ),
                    _buildGuideStep(
                      step: '02',
                      title: 'Phase II: Preferences',
                      description: 'This is the most critical part. You must list your college + course combinations in order of priority.',
                      color: Colors.orange,
                    ),
                    _buildGuideStep(
                      step: '03',
                      title: 'Phase III: Allocation',
                      description: 'DU will allot seats based on your rank, category, and preference list. You must "Accept" the seat to proceed.',
                      color: Colors.green,
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle('Pro Tips for Success', theme),
                  const SizedBox(height: 16),
                  _buildTopicCard(
                    theme,
                    icon: LucideIcons.layers,
                    title: 'Upgrade vs Freeze',
                    content: 'If you get your 3rd preference, you can "Upgrade" to try for 1st or 2nd in the next round. If you are happy, "Freeze" your seat.',
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 16),
                  _buildTopicCard(
                    theme,
                    icon: LucideIcons.alertTriangle,
                    title: 'The "Tie-Break" Rule',
                    content: 'When scores are equal, DU looks at Class 12th percentages, then age, then alphabetical order of names.',
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  _buildTopicCard(
                    theme,
                    icon: LucideIcons.fileText,
                    title: 'Document Checklist',
                    content: 'Keep your 10th/12th Marksheets, Category Certificates (EWS/OBC-NCL/SC/ST), and CUET Scorecard ready.',
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.bookOpen, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          Text(
            'Mastering DU Admissions',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A comprehensive guide to help you navigate the CSAS counselling process like a pro.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: theme.textTheme.displayLarge?.color,
      ),
    );
  }

  Widget _buildGuideStep({required String step, required String title, required String description, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              step,
              style: GoogleFonts.outfit(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
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
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(ThemeData theme, {required IconData icon, required String title, required String content, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
