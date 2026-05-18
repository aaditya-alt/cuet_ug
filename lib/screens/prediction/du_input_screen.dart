import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/du_predictor_service.dart';
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

  final TextEditingController _scoreController = TextEditingController();

  String _selectedCategory = 'UR';
  final List<String> _categories = ['UR', 'OBC', 'SC', 'ST', 'EWS', 'PwBD'];

  String _selectedGender = 'Female';
  final List<String> _genders = ['Male', 'Female', 'Other'];

  String _selectedPreferredDegree = 'Any';
  final List<String> _degrees = [
    'Any',
    'B.A.',
    'B.Sc.',
    'B.Com.',
    'B.Tech.',
    'BMS',
    'BBA',
    'B.Voc.',
    'B.El.Ed.',
    'BFA',
    'Other'
  ];

  final int _selectedYear = 2025;

  List<String> _allLanguages = [];
  List<String> _allDomains = [];
  bool _isLoadingSubjects = true;

  // Selected subjects
  final Set<String> _selectedLanguages = {};
  final Set<String> _selectedDomains = {};
  bool _studentHasGat = false;
  bool _isPredicting = false;

  @override
  void initState() {
    super.initState();
    _fetchSubjectLists();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubjectLists() async {
    try {
      final res = await _client.from('cuet_subject_lists').select();
      final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(res);
      
      final Set<String> langs = {};
      final Set<String> domains = {};
      
      for (final row in list) {
        final listName = row['list_name'] as String;
        final subjectName = row['subject'] as String;
        
        if (listName.toUpperCase() == 'A') {
          langs.add(subjectName);
        } else {
          domains.add(subjectName);
        }
      }

      setState(() {
        _allLanguages = langs.toList()..sort();
        _allDomains = domains.toList()..sort();
        _isLoadingSubjects = false;
      });
    } catch (e) {
      setState(() => _isLoadingSubjects = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load CUET subject lists: $e')),
        );
      }
    }
  }

  void _onPredictPressed() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLanguages.isEmpty || _selectedLanguages.length > 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select 1 or 2 Language subjects from List A.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedDomains.isEmpty || _selectedDomains.length > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select 1 to 3 Domain subjects from List B.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final double? score = double.tryParse(_scoreController.text);
    if (score == null || score <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid composite CUET score.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isPredicting = true);

    try {
      final results = await _predictorService.predict(
        studentLanguages: _selectedLanguages.toList(),
        studentDomains: _selectedDomains.toList(),
        studentHasGat: _studentHasGat,
        studentScore: score,
        studentCategory: _selectedCategory,
        studentGender: _selectedGender,
        preferredDegree: _selectedPreferredDegree,
        year: _selectedYear,
      );

      if (mounted) {
        setState(() => _isPredicting = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DuCollegeListScreen(
              colleges: results,
              category: _selectedCategory,
              year: _selectedYear,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPredicting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prediction failed: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: Text(
          'DU College Predictor',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Composite Score Card (Center Stage) ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(isDark ? 0.05 : 0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'ENTER YOUR COMPOSITE CUET SCORE',
                          style: GoogleFonts.outfit(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: 220,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: TextFormField(
                            controller: _scoreController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. 741.73',
                              hintStyle: GoogleFonts.outfit(
                                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                                fontSize: 28,
                                fontWeight: FontWeight.normal,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final val = double.tryParse(v);
                              if (val == null || val <= 0) return 'Invalid Score';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ensure this is your consolidated DU admission score, not subject-wise.',
                          style: GoogleFonts.outfit(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Filters & Selectors Grid ──
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField<String>(
                          label: 'Category',
                          value: _selectedCategory,
                          items: _categories,
                          icon: LucideIcons.shield,
                          onChanged: (v) => setState(() => _selectedCategory = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdownField<String>(
                          label: 'Gender',
                          value: _selectedGender,
                          items: _genders,
                          icon: LucideIcons.user,
                          onChanged: (v) => setState(() => _selectedGender = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildDropdownField<String>(
                    label: 'Preferred Degree',
                    value: _selectedPreferredDegree,
                    items: _degrees,
                    icon: LucideIcons.graduationCap,
                    onChanged: (v) => setState(() => _selectedPreferredDegree = v!),
                  ),
                  const SizedBox(height: 24),

                  // ── General Aptitude Test Toggle ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        'General Aptitude Test (GAT)',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        'Check this if you appeared for the GAT in CUET',
                        style: GoogleFonts.outfit(fontSize: 12),
                      ),
                      secondary: Icon(
                        LucideIcons.sparkles,
                        color: _studentHasGat ? theme.colorScheme.primary : Colors.grey,
                      ),
                      value: _studentHasGat,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (v) => setState(() => _studentHasGat = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Subject Lists Loader ──
                  if (_isLoadingSubjects)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    // ── Languages Appeared (List A) ──
                    Text(
                      'Languages Appeared (List A) (${_selectedLanguages.length}/2)',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select exactly 1 or 2 languages you studied in CUET',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allLanguages.map((subject) {
                        final isSelected = _selectedLanguages.contains(subject);
                        return ChoiceChip(
                          avatar: isSelected ? const Icon(LucideIcons.check, size: 14, color: Colors.white) : null,
                          label: Text(subject),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                if (_selectedLanguages.length < 2) {
                                  _selectedLanguages.add(subject);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('You can select a maximum of 2 languages.')),
                                  );
                                }
                              } else {
                                _selectedLanguages.remove(subject);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // ── Domains Appeared (List B) ──
                    Text(
                      'Domain Subjects Appeared (List B) (${_selectedDomains.length}/3)',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select 1 to 3 domain subjects you appeared for in CUET',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allDomains.map((subject) {
                        final isSelected = _selectedDomains.contains(subject);
                        return ChoiceChip(
                          avatar: isSelected ? const Icon(LucideIcons.check, size: 14, color: Colors.white) : null,
                          label: Text(subject),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                if (_selectedDomains.length < 3) {
                                  _selectedDomains.add(subject);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('You can select a maximum of 3 domain subjects.')),
                                  );
                                }
                              } else {
                                _selectedDomains.remove(subject);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Predict Button Sticky Footer ──
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoadingSubjects || _isPredicting ? null : _onPredictPressed,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: _isPredicting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'Predict My Colleges',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required IconData icon,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).inputDecorationTheme.fillColor ?? Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: const Icon(LucideIcons.chevronDown, size: 16),
              items: items.map((e) {
                String displayStr = e.toString();
                if (e is int && label.contains('Round')) {
                  displayStr = 'Round $e (2025)';
                }
                return DropdownMenuItem(
                  value: e,
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        displayStr,
                        style: GoogleFonts.outfit(fontSize: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
