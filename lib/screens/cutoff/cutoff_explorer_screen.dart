import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CutoffExplorerScreen extends StatefulWidget {
  const CutoffExplorerScreen({super.key});

  @override
  State<CutoffExplorerScreen> createState() => _CutoffExplorerScreenState();
}

class _CutoffExplorerScreenState extends State<CutoffExplorerScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoadingColleges = true;
  List<String> _colleges = [];
  String? _selectedCollege;

  bool _isLoadingPrograms = false;
  List<String> _programs = [];
  String? _selectedProgram;

  final List<String> _categories = ['UR', 'OBC', 'SC', 'ST', 'EWS'];
  String _selectedCategory = 'UR';

  bool _isLoadingCutoffs = false;
  List<Map<String, dynamic>> _cutoffs = [];

  @override
  void initState() {
    super.initState();
    _fetchColleges();
  }

  Future<void> _fetchColleges() async {
    try {
      final res = await _supabase
          .from('du_college_details')
          .select('college_name')
          .order('college_name');
      final list = (res as List)
          .map((e) => e['college_name'] as String)
          .toList();
      setState(() {
        _colleges = list;
        if (list.isNotEmpty) _selectedCollege = list.first;
        _isLoadingColleges = false;
      });
      if (_selectedCollege != null) _fetchPrograms(_selectedCollege!);
    } catch (e) {
      debugPrint('Error fetching colleges: $e');
      setState(() => _isLoadingColleges = false);
    }
  }

  Future<void> _fetchPrograms(String college) async {
    setState(() => _isLoadingPrograms = true);
    try {
      final res = await _supabase
          .from('du_cutoffs')
          .select('program_name')
          .eq('college_name', college);
      final rawList = (res as List)
          .map((e) => e['program_name'] as String)
          .toSet()
          .toList();
      rawList.sort();
      setState(() {
        _programs = rawList;
        if (rawList.isNotEmpty && !rawList.contains(_selectedProgram)) {
          _selectedProgram = rawList.first;
        }
        _isLoadingPrograms = false;
      });
      if (_selectedProgram != null) _fetchCutoffs();
    } catch (e) {
      debugPrint('Error fetching programs: $e');
      setState(() => _isLoadingPrograms = false);
    }
  }

  Future<void> _fetchCutoffs() async {
    if (_selectedCollege == null || _selectedProgram == null) return;
    setState(() => _isLoadingCutoffs = true);
    try {
      final res = await _supabase
          .from('du_cutoffs')
          .select()
          .eq('college_name', _selectedCollege!)
          .eq('program_name', _selectedProgram!)
          .eq('category', _selectedCategory)
          .order('round');
      setState(() {
        _cutoffs = List<Map<String, dynamic>>.from(res);
        _isLoadingCutoffs = false;
      });
    } catch (e) {
      debugPrint('Error fetching cutoffs: $e');
      setState(() => _isLoadingCutoffs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cutoff Explorer')),
      body: _isLoadingColleges
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select College & Course',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // College Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCollege,
                        items: _colleges
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCollege = val;
                            });
                            _fetchPrograms(val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Program Dropdown
                  _isLoadingPrograms
                      ? const Center(child: CircularProgressIndicator())
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedProgram,
                              items: _programs
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(
                                        p,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedProgram = val;
                                  });
                                  _fetchCutoffs();
                                }
                              },
                            ),
                          ),
                        ),
                  const SizedBox(height: 16),
                  Text(
                    'Category',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((c) {
                      final isSel = c == _selectedCategory;
                      return ChoiceChip(
                        label: Text(c),
                        selected: isSel,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedCategory = c);
                            _fetchCutoffs();
                          }
                        },
                        selectedColor: theme.colorScheme.primary.withOpacity(
                          0.2,
                        ),
                        labelStyle: GoogleFonts.outfit(
                          color: isSel
                              ? theme.colorScheme.primary
                              : Colors.black87,
                          fontWeight: isSel
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  // Chart area
                  Expanded(
                    child: _isLoadingCutoffs
                        ? const Center(child: CircularProgressIndicator())
                        : _cutoffs.isEmpty
                        ? Center(
                            child: Text(
                              'No cutoff data available for this selection.',
                              style: GoogleFonts.outfit(color: Colors.grey),
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: 800,
                                    minY: 0,
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipColor: (_) => Colors.blueGrey,
                                        getTooltipItem:
                                            (group, groupIndex, rod, rodIndex) {
                                              return BarTooltipItem(
                                                'Round ${group.x}\n${rod.toY.round()} marks',
                                                GoogleFonts.outfit(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: Text(
                                                'Round ${value.toInt()}',
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            );
                                          },
                                          reservedSize: 30,
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            if (value % 200 != 0)
                                              return const SizedBox.shrink();
                                            return Text(
                                              value.toInt().toString(),
                                              style: GoogleFonts.outfit(
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                          reservedSize: 40,
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: 100,
                                      getDrawingHorizontalLine: (value) =>
                                          FlLine(
                                            color: Colors.grey.shade200,
                                            strokeWidth: 1,
                                          ),
                                    ),
                                    barGroups: _cutoffs.map((row) {
                                      final round = (row['round'] as num)
                                          .toInt();
                                      final score = (row['cutoff_score'] as num)
                                          .toDouble();
                                      return BarChartGroupData(
                                        x: round,
                                        barRods: [
                                          BarChartRodData(
                                            toY: score,
                                            color: theme.colorScheme.primary,
                                            width: 24,
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(6),
                                                ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildSummaryRow(theme),
                            ],
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme) {
    if (_cutoffs.isEmpty) return const SizedBox.shrink();

    double min = double.infinity;
    double max = 0;
    for (var c in _cutoffs) {
      final s = (c['cutoff_score'] as num).toDouble();
      if (s < min) min = s;
      if (s > max) max = s;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statBox(
          'Highest Cutoff',
          max.toInt().toString(),
          theme.colorScheme.primary,
        ),
        _statBox('Lowest Cutoff', min.toInt().toString(), Colors.green),
        _statBox('Rounds', _cutoffs.length.toString(), Colors.orange),
      ],
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
