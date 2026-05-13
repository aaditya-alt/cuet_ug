import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/mock_data.dart';
import '../../models/college_model.dart';

class CompareScreen extends StatelessWidget {
  final CollegeModel college1;
  final CollegeModel college2;

  const CompareScreen({super.key, required this.college1, required this.college2});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Colleges'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildCollegeHeader(context, college1)),
                const SizedBox(width: 16),
                const Text('VS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(width: 16),
                Expanded(child: _buildCollegeHeader(context, college2)),
              ],
            ),
            const SizedBox(height: 32),
            _buildComparisonRow('Campus', college1.campus, college2.campus),
            _buildComparisonRow('Type', college1.type, college2.type),
            _buildComparisonRow('NIRF Rank', '#${college1.nirfRanking}', '#${college2.nirfRanking}'),
            _buildComparisonRow(
              'Highest Package', 
              college1.placementInfo?.highestPackage ?? 'N/A', 
              college2.placementInfo?.highestPackage ?? 'N/A'
            ),
            _buildComparisonRow(
              'Avg Package', 
              college1.placementInfo?.averagePackage ?? 'N/A', 
              college2.placementInfo?.averagePackage ?? 'N/A'
            ),
            _buildComparisonRow(
              'Expected Cutoff', 
              '${college1.courses.first.cutoffs['General']?.expected2026 ?? 0}', 
              '${college2.courses.first.cutoffs['General']?.expected2026 ?? 0}'
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollegeHeader(BuildContext context, CollegeModel college) {
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              college.logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(LucideIcons.building, color: Theme.of(context).colorScheme.primary, size: 40),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          college.name,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildComparisonRow(String label, String val1, String val2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(val1, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold))),
              const SizedBox(width: 48), // space for VS
              Expanded(child: Text(val2, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold))),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }
}
