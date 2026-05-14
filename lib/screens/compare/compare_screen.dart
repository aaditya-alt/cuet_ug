import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/college_model.dart';
import '../../providers/compare_provider.dart';

class CompareScreen extends StatelessWidget {
  final CollegeModel college1;
  final CollegeModel college2;

  const CompareScreen({super.key, required this.college1, required this.college2});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compareProvider = Provider.of<CompareProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Colleges'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            onPressed: () {
              compareProvider.clearCompare();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Headers
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCollegeHeader(context, college1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 30),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      'VS',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildCollegeHeader(context, college2)),
              ],
            ),
            const SizedBox(height: 32),
            
            // Comparison Table
            _buildComparisonSection(theme, 'General Info', [
              _buildComparisonRow('Campus', college1.campus, college2.campus),
              _buildComparisonRow('Type', college1.type, college2.type),
              _buildComparisonRow('NIRF 2025', '#${college1.nirfRanking}', '#${college2.nirfRanking}'),
            ]),
            
            const SizedBox(height: 24),
            _buildComparisonSection(theme, 'Placements', [
              _buildComparisonRow('Highest Package', college1.placementInfo?.highestPackage ?? 'N/A', college2.placementInfo?.highestPackage ?? 'N/A'),
              _buildComparisonRow('Average Package', college1.placementInfo?.averagePackage ?? 'N/A', college2.placementInfo?.averagePackage ?? 'N/A'),
              _buildComparisonRow('Placement %', '${college1.placementInfo?.placementPercentage}%', '${college2.placementInfo?.placementPercentage}%'),
            ]),
            
            const SizedBox(height: 24),
            _buildComparisonSection(theme, 'Facilities', [
              _buildComparisonRow('Hostel Fee', college1.hostelInfo?.fee ?? 'N/A', college2.hostelInfo?.fee ?? 'N/A'),
              _buildComparisonRow('Metro Connectivity', college1.nearbyMetro.split(',').first, college2.nearbyMetro.split(',').first),
            ]),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCollegeHeader(BuildContext context, CollegeModel college) {
    return Column(
      children: [
        Container(
          height: 90,
          width: 90,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Image.network(
            college.logoUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(LucideIcons.building, color: Theme.of(context).colorScheme.primary, size: 40),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          college.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, height: 1.2),
        ),
      ],
    );
  }

  Widget _buildComparisonSection(ThemeData theme, String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            children: rows,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonRow(String label, String val1, String val2) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  val1,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  val2,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
