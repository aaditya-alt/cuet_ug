import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/college_model.dart';
import '../../data/mock_data.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/navigation_provider.dart';

class SharedWishlistScreen extends StatelessWidget {
  final List<String> collegeIds;

  const SharedWishlistScreen({super.key, required this.collegeIds});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Resolve IDs or Names to College Models from MockData
    final List<CollegeModel> sharedColleges = collegeIds
        .map((idOrName) {
          try {
            final decoded = Uri.decodeComponent(idOrName).toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
            return MockData.colleges.firstWhere((c) {
              final collegeNameLower = c.name.toLowerCase().trim();
              final collegeIdLower = c.id.toLowerCase().trim();
              return collegeIdLower == decoded || 
                     collegeNameLower == decoded || 
                     collegeNameLower.contains(decoded) ||
                     decoded.contains(collegeNameLower);
            });
          } catch (_) {
            return null;
          }
        })
        .whereType<CollegeModel>()
        .toList();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0E14)
          : const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(
          'Shared Preference List',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: sharedColleges.isEmpty
          ? _buildEmptyOrInvalidState(context)
          : Column(
              children: [
                // Promotion Header Banner
                _buildPromotionBanner(context),

                // List of Colleges
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: sharedColleges.length,
                    itemBuilder: (context, index) {
                      final college = sharedColleges[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.dividerColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Rank Number
                              Container(
                                width: 30,
                                alignment: Alignment.center,
                                child: Text(
                                  '#${index + 1}',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Logo
                              Container(
                                width: 45,
                                height: 45,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Image.network(
                                  college.logoUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      LucideIcons.building,
                                      color: Colors.blue,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            college.name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            '${college.campus} Campus • ${college.type}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'NIRF #${college.nirfRanking}',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Import Actions Panel
                _buildActionPanel(context, sharedColleges),
              ],
            ),
    );
  }

  Widget _buildEmptyOrInvalidState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.heartOff, size: 64, color: Colors.red),
            const SizedBox(height: 24),
            Text(
              'Invalid Preference Link',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any colleges matching the IDs in this shared link.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
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
            child: const Icon(
              LucideIcons.graduationCap,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Predict Your Dream College!',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Predict with 99% accuracy using DU Cutoff Predictor 2025.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPanel(
    BuildContext context,
    List<CollegeModel> sharedColleges,
  ) {
    final theme = Theme.of(context);
    final wishlistProvider = Provider.of<WishlistProvider>(
      context,
      listen: false,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              // Present choices to merge or overwrite
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'Import Preference List',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    'Would you like to merge this list with your existing local preferences or overwrite it completely?',
                    style: GoogleFonts.outfit(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        // Merge
                        for (var college in sharedColleges) {
                          if (!wishlistProvider.isInWishlist(college.id)) {
                            wishlistProvider.toggleWishlist(college);
                          }
                        }
                        Navigator.pop(context);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Preferences merged into your local list!',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: Text(
                        'Merge Lists',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Overwrite
                        wishlistProvider.clearWishlist();
                        for (var college in sharedColleges) {
                          wishlistProvider.toggleWishlist(college);
                        }
                        Navigator.pop(context);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Preferences overwritten successfully!',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: Text(
                        'Overwrite',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(Icons.import_contacts),
            label: Text(
              'Import to My Preferences',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              // Switch navigation tab to predictor hub (discovery or prediction index)
              Provider.of<NavigationProvider>(
                context,
                listen: false,
              ).setIndex(1); // Go to College Discovery Tab
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
            child: Text(
              'Predict My Dream College Now',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
