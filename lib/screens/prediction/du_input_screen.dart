import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/du_models.dart';
import '../../providers/du_predictor_service.dart';
import '../premium/premium_screen.dart';
import 'du_college_list_screen.dart';

class DuInputScreen extends StatefulWidget {
  const DuInputScreen({super.key});

  @override
  State<DuInputScreen> createState() => _DuInputScreenState();
}

class _DuInputScreenState extends State<DuInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _client = Supabase.instance.client;
  final DuPredictorService _predictorService = DuPredictorService();

  String _selectedCategory = 'UR';
  final List<String> _categories = ['UR', 'OBC', 'SC', 'ST', 'EWS', 'PwBD'];

  String _selectedGender = 'Female';
  final List<String> _genders = ['Male', 'Female'];

  int _selectedRound = 1;
  int _selectedYear = 2025;
  
  List<int> _availableRounds = [1, 2, 3];
  List<int> _availableYears = [2025];

  List<Map<String, dynamic>> _subjectList = [];
  bool _isLoadingSubjects = true;

  // Selected subjects by the user
  final List<_SubjectEntry> _selectedSubjects = [];
  bool _includeGT = false;
  final TextEditingController _gtScoreController = TextEditingController();

  // Placeholder for Premium state
  bool _isPremium = false; // Set to true to test the predictor
  bool _isPredicting = false;

  double get _totalScore {
    List<double> scores = [];

    // Collect subject scores
    for (var entry in _selectedSubjects) {
      if (entry.scoreController.text.isNotEmpty) {
        scores.add(double.tryParse(entry.scoreController.text) ?? 0);
      }
    }

    // Sort descending to pick best ones
    scores.sort((a, b) => b.compareTo(a));

    double gt = (_includeGT && _gtScoreController.text.isNotEmpty) 
        ? (double.tryParse(_gtScoreController.text) ?? 0) 
        : 0;
    bool hasGT = _includeGT && _gtScoreController.text.isNotEmpty;

    if (scores.length >= 4) {
      // 4 or more subjects -> Take best 4 (ignore GT for the 1000 marks if subjects >= 4)
      return scores.take(4).reduce((a, b) => a + b);
    } else if (scores.length == 3 && hasGT) {
      // 3 subjects + GT -> 4 items (1000 marks)
      return scores.reduce((a, b) => a + b) + gt;
    } else if (scores.length == 3 && !hasGT) {
      // 3 subjects only -> Pro-rate 750 to 1000
      double raw = scores.reduce((a, b) => a + b);
      return (raw / 750) * 1000;
    } else if (scores.length == 2 && hasGT) {
      // 2 subjects + GT -> 3 items -> Pro-rate 750 to 1000
      double raw = scores.reduce((a, b) => a + b) + gt;
      return (raw / 750) * 1000;
    } else {
      // Fallback: just sum whatever we have
      double currentSum = (scores.isEmpty ? 0 : scores.reduce((a, b) => a + b)) + gt;
      return currentSum;
    }
  }

  int get _itemsCount {
    int count = 0;
    for (var entry in _selectedSubjects) {
      if (entry.scoreController.text.isNotEmpty && entry.selectedSubject != null) {
        count++;
      }
    }
    if (_includeGT && _gtScoreController.text.isNotEmpty) {
      count++;
    }
    return count;
  }

  @override
  void initState() {
    super.initState();
    _fetchSubjectList();
    _fetchAvailableRoundsAndYears();
    // Add 2 subject rows by default
    for (int i = 0; i < 2; i++) {
      _addSubjectRow();
    }
    // Wait, I should add listeners to controllers to update UI on score change
    _gtScoreController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _gtScoreController.dispose();
    for (var entry in _selectedSubjects) {
      entry.scoreController.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchSubjectList() async {
    try {
      final res = await _client.from('cuet_subject_lists').select();
      setState(() {
        _subjectList = List<Map<String, dynamic>>.from(res);
        _isLoadingSubjects = false;
      });
    } catch (e) {
      setState(() => _isLoadingSubjects = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load subjects')));
      }
    }
  }

  Future<void> _fetchAvailableRoundsAndYears() async {
    try {
      // Typically we might query distinct rounds and years. 
      // Mocking the result to [1, 2, 3] and [2025] for now as per requirements.
      setState(() {
        _availableRounds = [1, 2, 3];
        _availableYears = [2025];
      });
    } catch (e) {
      // fallback
    }
  }

  void _addSubjectRow() {
    final entry = _SubjectEntry();
    entry.scoreController.addListener(() => setState(() {}));
    setState(() {
      _selectedSubjects.add(entry);
    });
  }

  void _removeSubjectRow(int index) {
    setState(() {
      _selectedSubjects[index].scoreController.dispose();
      _selectedSubjects.removeAt(index);
    });
  }

  void _onPredictPressed() async {
    if (!_formKey.currentState!.validate()) return;

    final userSubjects = <UserCuetSubject>[];

    for (var entry in _selectedSubjects) {
      if (entry.selectedSubject != null && entry.scoreController.text.isNotEmpty) {
        final score = double.tryParse(entry.scoreController.text) ?? 0;
        final subjInfo = _subjectList.firstWhere((s) => s['subject'] == entry.selectedSubject);
        userSubjects.add(UserCuetSubject(
          name: entry.selectedSubject!,
          list: subjInfo['list_name'] as String,
          score: score,
        ));
      }
    }



    if (_itemsCount < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least 3 items (Subjects + General Test).'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_includeGT && _gtScoreController.text.isNotEmpty) {
      final score = double.tryParse(_gtScoreController.text) ?? 0;
      userSubjects.add(UserCuetSubject(
        name: 'General Test',
        list: 'General Test',
        score: score,
      ));
    }

    if (userSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one subject with a score.')),
      );
      return;
    }

    setState(() => _isPredicting = true);

    try {
      final results = await _predictorService.predict(
        category: _selectedCategory,
        round: _selectedRound,
        year: _selectedYear,
        userSubjects: userSubjects,
        gender: _selectedGender,
      );

      if (mounted) {
        setState(() => _isPredicting = false);

        // Check if any programs were scaled (pro-rated)
        bool hasScaled = false;
        List<DuProgramResult> topScaled = [];
        for (var college in results) {
          for (var prog in college.programs) {
            if (prog.isScaled) {
              hasScaled = true;
              if (topScaled.length < 3) topScaled.add(prog);
            }
          }
        }

        if (hasScaled) {
          final shouldProceed = await _showProRateConfirmation(topScaled);
          if (shouldProceed != true) return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DuCollegeListScreen(
              colleges: results,
              category: _selectedCategory,
              round: _selectedRound,
              year: _selectedYear,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPredicting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prediction failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('DU CUET Predictor', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Category & Gender ──
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown<String>(
                          label: 'Category',
                          value: _selectedCategory,
                          items: _categories,
                          onChanged: (v) => setState(() => _selectedCategory = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdown<String>(
                          label: 'Gender',
                          value: _selectedGender,
                          items: _genders,
                          onChanged: (v) => setState(() => _selectedGender = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Total Marks Indicator ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(LucideIcons.trophy, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cumulative Score',
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${_totalScore.toStringAsFixed(0)} / 1000',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                value: _totalScore / 1000,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                color: Colors.white,
                                strokeWidth: 6,
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Text(
                              '${(_totalScore / 10).toStringAsFixed(0)}%',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text('CUET Subjects Appeared', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  if (_isLoadingSubjects)
                    const Center(child: CircularProgressIndicator())
                  else
                    ..._selectedSubjects.asMap().entries.map((e) {
                      final idx = e.key;
                      final entry = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: entry.selectedSubject,
                                decoration: InputDecoration(
                                  labelText: 'Select Subject',
                                  labelStyle: GoogleFonts.outfit(fontSize: 14),
                                ),
                                isExpanded: true,
                                items: _subjectList.map((s) {
                                  return DropdownMenuItem<String>(
                                    value: s['subject'] as String,
                                    child: Text(
                                      s['subject'] as String,
                                      style: GoogleFonts.outfit(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => entry.selectedSubject = v),
                                validator: (v) => v == null ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: entry.scoreController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Score',
                                  labelStyle: GoogleFonts.outfit(fontSize: 14),
                                ),
                                style: GoogleFonts.outfit(fontSize: 14),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Req';
                                  final num = double.tryParse(v);
                                  if (num == null || num < 0 || num > 250) return '0-250';
                                  return null;
                                },
                              ),
                            ),
                            if (_selectedSubjects.length > 1)
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
                                onPressed: () => _removeSubjectRow(idx),
                              ),
                          ],
                        ),
                      );
                    }).toList(),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _selectedSubjects.length < 5 ? _addSubjectRow : null,
                      icon: const Icon(LucideIcons.plus),
                      label: Text('Add Domain/Language (Max 5)', style: GoogleFonts.outfit()),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? theme.colorScheme.surface : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: Text('General Test', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          subtitle: Text('Check if you appeared for GT', style: GoogleFonts.outfit(fontSize: 12)),
                          value: _includeGT,
                          onChanged: (v) => setState(() => _includeGT = v ?? false),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: theme.colorScheme.primary,
                        ),
                        if (_includeGT)
                          TextFormField(
                            controller: _gtScoreController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'General Test Score (out of 250)'),
                            style: GoogleFonts.outfit(fontSize: 14),
                            validator: (v) {
                              if (!_includeGT) return null;
                              if (v == null || v.isEmpty) return 'Required';
                              final num = double.tryParse(v);
                              if (num == null || num < 0 || num > 250) return '0-250';
                              return null;
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  
                  const SizedBox(height: 100), // spacing for bottom button
                ],
              ),
            ),
          ),

          // Predict Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoadingSubjects || _isPredicting || _itemsCount < 3 ? null : _onPredictPressed,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: _itemsCount < 3 ? Colors.grey : theme.colorScheme.primary,
                ),
                child: _isPredicting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _itemsCount < 3 ? 'Add at least 3 items' : 'Predict Colleges', 
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: const Icon(LucideIcons.chevronDown, size: 16),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toString(), style: GoogleFonts.outfit(fontSize: 14)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
  Future<bool?> _showProRateConfirmation(List<DuProgramResult> scaledPrograms) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(LucideIcons.scale, color: Colors.orange),
            const SizedBox(width: 12),
            Text('Pro-rated Score Alert', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Some courses use a combination of only 3 subjects (out of 750). To maintain consistency, we have pro-rated these marks out of 1000.',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            Text(
              'Example Pro-rated Scores:',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 12),
            ...scaledPrograms.take(2).map((p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.programName, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('Original: ${p.originalScore?.toStringAsFixed(0)} / ${p.originalTotal}', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.arrowRight, size: 14, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '${p.userScore.toStringAsFixed(0)}/1000',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            Text(
              'Are you ready to proceed with this calculation?',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Go Back', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Yes, Proceed', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SubjectEntry {
  String? selectedSubject;
  final TextEditingController scoreController = TextEditingController();
}
