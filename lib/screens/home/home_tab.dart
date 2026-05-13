import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/user_score_provider.dart';
import '../prediction/prediction_results_screen.dart';
import '../analytics/analytics_tab.dart';
import '../wishlist/wishlist_tab.dart';
import '../notifications/notification_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreProvider = Provider.of<UserScoreProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi Abhinav 👋',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.displayLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Let\'s predict your dream college',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationScreen()),
                        );
                      },
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Main Card
              Container(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.calculator, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          'Enter CUET Score',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Score Inputs
                    _buildScoreRow(
                      context,
                      'Language',
                      'Domain 1',
                      (val) => scoreProvider.updateEnglish(double.tryParse(val) ?? 0),
                      (val) => scoreProvider.updateDomain1(double.tryParse(val) ?? 0),
                    ),
                    const SizedBox(height: 16),
                    _buildScoreRow(
                      context,
                      'Domain 2',
                      'Domain 3',
                      (val) => scoreProvider.updateDomain2(double.tryParse(val) ?? 0),
                      (val) => scoreProvider.updateDomain3(double.tryParse(val) ?? 0),
                    ),
                    const SizedBox(height: 16),
                    _buildScoreInput(
                      context,
                      'General Test (Optional)',
                      (val) => scoreProvider.updateGeneralTest(double.tryParse(val) ?? 0),
                      isFullWidth: true,
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Dropdowns
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
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            context,
                            'PwD Quota',
                            'No',
                            ['No', 'Yes'],
                            (val) {}, // Mock PwD logic
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PredictionResultsScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Predict Colleges',
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
              Text(
                'Quick Actions',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAction(context, LucideIcons.building, 'All Colleges', Colors.blue, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PredictionResultsScreen()));
                  }),
                  _buildQuickAction(context, LucideIcons.bookOpen, 'Course Cutoffs', Colors.green, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsTab()));
                  }),
                  _buildQuickAction(context, LucideIcons.list, 'CSAS Rounds', Colors.orange, onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSAS Rounds feature coming soon')));
                  }),
                  _buildQuickAction(context, LucideIcons.heart, 'My Wishlist', Colors.red, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const WishlistTab()));
                  }),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(BuildContext context, String label1, String label2, Function(String) onChanged1, Function(String) onChanged2) {
    return Row(
      children: [
        Expanded(child: _buildScoreInput(context, label1, onChanged1)),
        const SizedBox(width: 16),
        Expanded(child: _buildScoreInput(context, label2, onChanged2)),
      ],
    );
  }

  Widget _buildScoreInput(BuildContext context, String label, Function(String) onChanged, {bool isFullWidth = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: '0 / 200',
            suffixText: isFullWidth ? '/ 250' : '/ 200',
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(BuildContext context, String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(LucideIcons.chevronDown),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: GoogleFonts.outfit()),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        ],
      ),
    );
  }
}
