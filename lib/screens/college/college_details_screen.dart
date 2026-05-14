import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/college_model.dart';
import 'package:provider/provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/compare_provider.dart';
import '../compare/compare_screen.dart';

import 'package:share_plus/share_plus.dart';

class CollegeDetailsScreen extends StatefulWidget {
  final CollegeModel college;

  const CollegeDetailsScreen({super.key, required this.college});

  @override
  State<CollegeDetailsScreen> createState() => _CollegeDetailsScreenState();
}

class _CollegeDetailsScreenState extends State<CollegeDetailsScreen> {
  late String _selectedCategory;
  late CourseCutoff _selectedCourse;

  CollegeModel get college => widget.college;

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'General';
    _selectedCourse = widget.college.courses.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final compareProvider = Provider.of<CompareProvider>(context);
    final college = widget.college;

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
                  _buildCutoffDetails(theme),
                  const SizedBox(height: 100), // Space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, theme, wishlistProvider, compareProvider),
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
          onPressed: () {
            final String text = 'Check out ${college.name} on Cuet Predictor!\n\n'
                '📍 Campus: ${college.campus}\n'
                '🏆 NIRF Rank: #${college.nirfRanking}\n'
                '🎓 Courses: ${college.courses.map((c) => c.courseName).take(3).join(", ")}...\n\n'
                'Open in App: cuet://college/${college.id}\n'
                'Or view on Web: https://cuetpredictor.app/college/${college.id}';
            Share.share(text);
          },
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

  Widget _buildCutoffDetails(ThemeData theme) {
    final categories = ['General', 'OBC', 'SC', 'ST', 'EWS'];
    final cutoffData = _selectedCourse.cutoffs[_selectedCategory];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Cutoff Insights'),
        const SizedBox(height: 16),
        
        // Course Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CourseCutoff>(
              isExpanded: true,
              value: _selectedCourse,
              items: widget.college.courses.map((course) {
                return DropdownMenuItem(
                  value: course,
                  child: Text(course.courseName, style: GoogleFonts.outfit(fontSize: 15)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCourse = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Category Selector (Horizontal Chips)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        if (cutoffData != null) ...[
          // Round-wise Stats
          Row(
            children: [
              _buildRoundCard('Round 1', cutoffData.round1.toStringAsFixed(0), theme),
              const SizedBox(width: 12),
              _buildRoundCard('Round 2', cutoffData.round2.toStringAsFixed(0), theme),
              const SizedBox(width: 12),
              _buildRoundCard('Round 3', cutoffData.round3.toStringAsFixed(0), theme),
            ],
          ),
          const SizedBox(height: 24),

          // Chart Section
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Round-wise Cutoff Visualization',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 800,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(fontSize: 10, fontWeight: FontWeight.bold);
                              switch (value.toInt()) {
                                case 0: return const Text('R1', style: style);
                                case 1: return const Text('R2', style: style);
                                case 2: return const Text('R3', style: style);
                                default: return const Text('');
                              }
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        _makeBarGroup(0, cutoffData.round1, theme.colorScheme.primary),
                        _makeBarGroup(1, cutoffData.round2, theme.colorScheme.secondary),
                        _makeBarGroup(2, cutoffData.round3, Colors.orange),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Phased Info / Expectations
          _buildPhasedInfo(cutoffData, theme),
        ],
      ],
    );
  }

  Widget _buildRoundCard(String label, String value, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 800,
            color: color.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildPhasedInfo(CategoryCutoff cutoff, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.trendingUp, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Admission Strategy',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStrategyItem('Target Score', '${cutoff.expected2026.toStringAsFixed(0)}+', 'Highly Safe'),
          const Divider(height: 24),
          _buildStrategyItem('Waitlist Chance', 'Medium', 'Wait for Round 2/3 if score is >${cutoff.round2.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _buildStrategyItem(String label, String value, String sub) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
            Text(sub, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
        Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
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

  Widget _buildBottomBar(BuildContext context, ThemeData theme, WishlistProvider wishlistProvider, CompareProvider compareProvider) {
    final isInCompare = compareProvider.isInCompare(college.id);
    final compareCount = compareProvider.count;

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
              onPressed: () {
                if (compareCount >= 2 && !isInCompare) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You can only compare 2 colleges at a time.'))
                  );
                  return;
                }
                
                compareProvider.toggleCompare(college);
                
                if (compareProvider.count == 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('2 colleges selected for comparison!'),
                      action: SnackBarAction(
                        label: 'COMPARE NOW',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CompareScreen(
                                college1: compareProvider.compareList[0],
                                college2: compareProvider.compareList[1],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                } else if (compareProvider.count == 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select one more college to compare.'))
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: isInCompare ? Colors.orange : theme.colorScheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: isInCompare ? Colors.orange.withOpacity(0.1) : null,
              ),
              child: Text(
                isInCompare ? 'Selected (${compareCount}/2)' : 'Compare', 
                style: GoogleFonts.outfit(
                  fontSize: 15, 
                  fontWeight: FontWeight.bold, 
                  color: isInCompare ? Colors.orange : theme.colorScheme.primary
                )
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                final wasInWishlist = wishlistProvider.isInWishlist(college.id);
                wishlistProvider.toggleWishlist(college);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      wasInWishlist 
                          ? '${college.name} removed from list' 
                          : '${college.name} added to list'
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: Icon(
                wishlistProvider.isInWishlist(college.id) ? LucideIcons.check : LucideIcons.plus,
                size: 18,
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: wishlistProvider.isInWishlist(college.id) 
                    ? Colors.green.shade50 
                    : theme.colorScheme.primary,
                foregroundColor: wishlistProvider.isInWishlist(college.id) 
                    ? Colors.green.shade700 
                    : Colors.white,
                elevation: 0,
                side: wishlistProvider.isInWishlist(college.id) 
                    ? BorderSide(color: Colors.green.shade200) 
                    : null,
              ),
              label: Text(
                wishlistProvider.isInWishlist(college.id) ? 'Added to List' : 'Add to List',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
