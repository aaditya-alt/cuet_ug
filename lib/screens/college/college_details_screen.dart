import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/college_model.dart';
import 'package:provider/provider.dart';
import '../../providers/wishlist_provider.dart';

class CollegeDetailsScreen extends StatelessWidget {
  final CollegeModel college;

  const CollegeDetailsScreen({super.key, required this.college});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, wishlistProvider),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 24),
                  _buildPhotoGallery(theme),
                  const SizedBox(height: 32),
                  _buildSectionTitle('About'),
                  const SizedBox(height: 8),
                  Text(
                    college.description,
                    style: GoogleFonts.outfit(
                      fontSize: 15, 
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7), 
                      height: 1.6
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildRankings(theme),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Courses & Fees'),
                  const SizedBox(height: 16),
                  _buildCoursesTable(theme),
                  const SizedBox(height: 32),
                  _buildPlacements(theme),
                  const SizedBox(height: 32),
                  _buildLocation(theme),
                  const SizedBox(height: 32),
                  _buildFacilities(theme),
                  const SizedBox(height: 32),
                  _buildHostel(theme),
                  const SizedBox(height: 32),
                  _buildCutoffTrends(theme),
                  const SizedBox(height: 100), // Space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, theme, wishlistProvider),
    );
  }

  Widget _buildAppBar(BuildContext context, WishlistProvider wishlistProvider) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              college.photos.isNotEmpty ? college.photos[0] : 'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&q=80&w=1000',
              fit: BoxFit.cover,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            wishlistProvider.isInWishlist(college.id) ? LucideIcons.heart : LucideIcons.heart,
            color: wishlistProvider.isInWishlist(college.id) ? Colors.red : Colors.white,
          ),
          onPressed: () => wishlistProvider.toggleWishlist(college),
        ),
        IconButton(
          icon: const Icon(LucideIcons.share2, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
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
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'NIRF #${college.nirfRanking}',
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(LucideIcons.mapPin, size: 14, color: theme.textTheme.bodySmall?.color),
            const SizedBox(width: 4),
            Text(
              '${college.campus} • ${college.type}',
              style: GoogleFonts.outfit(color: theme.textTheme.bodySmall?.color, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoGallery(ThemeData theme) {
    if (college.photos.length <= 1) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Campus Gallery'),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: college.photos.length - 1,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(college.photos[index + 1]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRankings(ThemeData theme) {
    if (college.rankings.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Rankings'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: college.rankings.map((rank) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? Colors.orange.shade50 : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.brightness == Brightness.light ? Colors.orange.shade100 : Colors.orange.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.award, size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    rank,
                    style: GoogleFonts.outfit(color: Colors.orange.shade900, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCoursesTable(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: college.courses.map((course) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.courseName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(course.duration, style: GoogleFonts.outfit(color: theme.textTheme.bodySmall?.color, fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    course.fee,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.outfit(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlacements(ThemeData theme) {
    final info = college.placementInfo;
    if (info == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Placements'),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatCard(theme, 'Highest', info.highestPackage, LucideIcons.trendingUp, Colors.green),
            const SizedBox(width: 12),
            _buildStatCard(theme, 'Average', info.averagePackage, LucideIcons.barChart, Colors.blue),
            const SizedBox(width: 12),
            _buildStatCard(theme, 'Placed', '${info.placementPercentage}%', LucideIcons.checkCircle, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(label, style: GoogleFonts.outfit(color: theme.textTheme.bodySmall?.color, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocation(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Location & Connectivity'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light ? Colors.grey.shade50 : theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.map, size: 18, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(college.address, style: GoogleFonts.outfit(fontSize: 14)),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  const Icon(LucideIcons.train, size: 18, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(college.nearbyMetro, style: GoogleFonts.outfit(fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFacilities(ThemeData theme) {
    if (college.facilities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Facilities'),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: college.facilities.length,
          itemBuilder: (context, index) {
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text(
                college.facilities[index],
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHostel(ThemeData theme) {
    final hostel = college.hostelInfo;
    if (hostel == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Hostel Information'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Hostel Fee', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                  Text(hostel.fee, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              Text(hostel.details, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: hostel.facilities.map((f) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(f, style: GoogleFonts.outfit(color: Colors.white, fontSize: 10)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCutoffTrends(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Cutoff Trends'),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    const FlSpot(0, 750),
                    const FlSpot(1, 765),
                    const FlSpot(2, 785),
                    const FlSpot(3, 780),
                  ],
                  isCurved: true,
                  color: theme.colorScheme.primary,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: theme.colorScheme.primary.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBottomBar(BuildContext context, ThemeData theme, WishlistProvider wishlistProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: theme.colorScheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Compare', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => wishlistProvider.toggleWishlist(college),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: wishlistProvider.isInWishlist(college.id) ? Colors.red.shade100 : theme.colorScheme.primary,
                foregroundColor: wishlistProvider.isInWishlist(college.id) ? Colors.red : Colors.white,
                elevation: 0,
              ),
              child: Text(
                wishlistProvider.isInWishlist(college.id) ? 'Remove' : 'Wishlist',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
