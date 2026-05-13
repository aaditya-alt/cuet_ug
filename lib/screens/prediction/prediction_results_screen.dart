import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/mock_data.dart';
import '../college/college_details_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/user_score_provider.dart';
import '../../providers/wishlist_provider.dart';

class PredictionResultsScreen extends StatelessWidget {
  const PredictionResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colleges = MockData.colleges;
    final scoreProvider = Provider.of<UserScoreProvider>(context);
    final userScore = scoreProvider.score.getTotalScore(false);
    final wishlistProvider = Provider.of<WishlistProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eligible Colleges'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.filter),
            onPressed: () {
              // Open filter drawer
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: colleges.length,
        itemBuilder: (context, index) {
          final college = colleges[index];
          
          double expectedCutoff = college.courses.first.cutoffs['General']?.expected2026 ?? 800;
          
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
                            wishlistProvider.toggleWishlist(college);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  wishlistProvider.isInWishlist(college.id)
                                      ? 'Removed from Wishlist'
                                      : 'Added to Wishlist',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
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
                        const Spacer(),
                        Text(
                          'Expected Cutoff: ',
                          style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600),
                        ),
                        Text(
                          '${expectedCutoff.toInt()}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
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
    );
  }
}
