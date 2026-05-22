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
  final SupabaseClient _client = Supabase.instance.client;
  final DuPredictorService _predictorService = DuPredictorService();
  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _isPredicting = false;

  // Step 1: Basic Details
  String _selectedCategory = 'UR';
  final List<String> _categories = ['UR', 'OBC', 'SC', 'ST', 'EWS', 'PwBD'];
  String _selectedGender = 'Female';
  final List<String> _genders = ['Male', 'Female', 'Other'];

  // Step 2: Subjects & Scores
  List<String> _allLanguages = [];
  List<String> _allDomains = [];
  bool _isLoadingSubjects = true;

  final Set<String> _selectedLanguages = {};
  final Set<String> _selectedDomains = {};
  final Map<String, TextEditingController> _scoreControllers = {};
  bool _studentHasGat = false;

  // Step 3: Preferences
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
    'Other',
  ];
  final int _selectedYear = 2025;
  // Add this field with the other controllers:
  final TextEditingController _gatScoreController = TextEditingController();

  // In dispose():

  @override
  void initState() {
    super.initState();
    _fetchSubjectLists();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _gatScoreController.dispose();
    for (var controller in _scoreControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchSubjectLists() async {
    try {
      final res = await _client.from('cuet_subject_lists').select();
      final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
        res,
      );

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

  TextEditingController _getScoreController(String subject) {
    if (!_scoreControllers.containsKey(subject)) {
      _scoreControllers[subject] = TextEditingController();
    }
    return _scoreControllers[subject]!;
  }

  void _nextStep() {
    if (_currentStep == 1) {
      // Validate Step 2 before proceeding
      if (_selectedLanguages.isEmpty || _selectedLanguages.length > 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select 1 or 2 Language subjects from List A.',
            ),
          ),
        );
        return;
      }

      if (_selectedDomains.isEmpty || _selectedDomains.length > 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select 1 to 4 Domain subjects from List B.'),
          ),
        );
        return;
      }

      if (_studentHasGat) {
        final gatText = _gatScoreController.text;
        final gatVal = double.tryParse(gatText);
        if (gatVal == null || gatVal < 0 || gatVal > 250) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid GAT score (0-250).'),
            ),
          );
          return;
        }
      }

      // Check if all selected subjects have valid scores
      bool hasInvalidScore = false;
      for (var subject in [..._selectedLanguages, ..._selectedDomains]) {
        final text = _getScoreController(subject).text;
        final val = double.tryParse(text);
        if (val == null || val < 0 || val > 250) {
          hasInvalidScore = true;
          break;
        }
      }

      if (hasInvalidScore) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter a valid score (0-250) for all selected subjects.',
            ),
          ),
        );
        return;
      }
    }

    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _onPredictPressed();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  void _onPredictPressed() async {
    setState(() => _isPredicting = true);

    try {
      final Map<String, double> langScores = {};
      for (var lang in _selectedLanguages) {
        langScores[lang] = double.parse(_getScoreController(lang).text);
      }

      final Map<String, double> domainScores = {};
      for (var domain in _selectedDomains) {
        domainScores[domain] = double.parse(_getScoreController(domain).text);
      }

      final results = await _predictorService.predict(
        langScores: langScores,
        domainScores: domainScores,
        studentHasGat: _studentHasGat,
        gatScore: _studentHasGat
            ? double.tryParse(_gatScoreController.text)
            : null,
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: isDark
                ? Colors.grey.shade800
                : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 20.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step ${_currentStep + 1} of 3',
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _currentStep == 0
                      ? 'Basic Details'
                      : _currentStep == 1
                      ? 'Subjects & Scores'
                      : 'Preferences',
                  style: GoogleFonts.outfit(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(theme, isDark),
                _buildStep2(theme, isDark),
                _buildStep3(theme, isDark),
              ],
            ),
          ),
          _buildFooter(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildStep1(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about yourself',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your category and gender play a significant role in determining your eligibility and cutoffs.',
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
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
              IconButton(
                icon: const Icon(LucideIcons.info),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Categories Explained'),
                      content: const Text(
                        'UR: Unreserved / General\nOBC: Other Backward Classes (Non-Creamy Layer)\nSC: Scheduled Caste\nST: Scheduled Tribe\nEWS: Economically Weaker Section\nPwBD: Persons with Benchmark Disabilities',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Got it'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDropdownField<String>(
            label: 'Gender',
            value: _selectedGender,
            items: _genders,
            icon: LucideIcons.user,
            onChanged: (v) => setState(() => _selectedGender = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme, bool isDark) {
    if (_isLoadingSubjects) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your CUET Performance',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the subjects you appeared for and enter your normalised NTA scores.',
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.info,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'For B.Sc. Science programs (like Chemistry, Botany), your language score is NOT counted in merit. We handle all DU scoring rules automatically!',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: isDark
                          ? Colors.blue.shade200
                          : Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Languages Appeared (List A) ──
          Text(
            'Languages (List A) - Select 1 or 2',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allLanguages.map((subject) {
              final isSelected = _selectedLanguages.contains(subject);
              return ChoiceChip(
                label: Text(subject),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      if (_selectedLanguages.length < 2) {
                        _selectedLanguages.add(subject);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'You can select a maximum of 2 languages.',
                            ),
                          ),
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
          if (_selectedLanguages.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._selectedLanguages
                .map((lang) => _buildScoreInput(lang, isDark, theme))
                .toList(),
          ],
          const SizedBox(height: 32),

          // ── Domains Appeared (List B) ──
          Text(
            'Domain Subjects (List B) - Select 1 to 4',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allDomains.map((subject) {
              final isSelected = _selectedDomains.contains(subject);
              return ChoiceChip(
                label: Text(subject),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      if (_selectedDomains.length < 4) {
                        _selectedDomains.add(subject);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'You can select a maximum of 4 domain subjects.',
                            ),
                          ),
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
          if (_selectedDomains.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._selectedDomains
                .map((domain) => _buildScoreInput(domain, isDark, theme))
                .toList(),
          ],
          const SizedBox(height: 32),

          // ── General Aptitude Test Toggle ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: Text(
                    'General Aptitude Test (GAT)',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Did you appear for the GAT section in CUET?',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                  ),
                  value: _studentHasGat,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (v) => setState(() => _studentHasGat = v),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_studentHasGat) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GAT Score',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Enter your NTA normalised score (0-250)',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _gatScoreController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'Max 250',
                            hintStyle: const TextStyle(fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.info,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'GAT score is used for B.Tech IT&MI, BMS, BBA-FIA, BBE, '
                            'B.A. Multimedia, B.Com, B.Voc, and B.A. Programme '
                            '(GAT combo). DU uses proration so these are comparable '
                            'to standard 1000-mark programmes.',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Preferences',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us narrow down the colleges and programs.',
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          _buildDropdownField<String>(
            label: 'Preferred Degree Program',
            value: _selectedPreferredDegree,
            items: _degrees,
            icon: LucideIcons.graduationCap,
            onChanged: (v) => setState(() => _selectedPreferredDegree = v!),
          ),
          const SizedBox(height: 48),
          Center(
            child: Icon(
              LucideIcons.checkCircle,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'All Set!',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Click below to see your predicted colleges.',
              style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreInput(String subject, bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              subject,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: TextFormField(
              controller: _getScoreController(subject),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Max 250',
                hintStyle: const TextStyle(fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final val = double.tryParse(v);
                if (val == null || val < 0 || val > 250) return '0-250';
                return null;
              },
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
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color:
                Theme.of(context).inputDecorationTheme.fillColor ??
                Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: const Icon(LucideIcons.chevronDown, size: 16),
              items: items.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        e.toString(),
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

  Widget _buildFooter(ThemeData theme, bool isDark) {
    return Container(
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
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isPredicting ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isPredicting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _currentStep == 2 ? 'Find My Colleges' : 'Continue',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
