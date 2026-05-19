import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/du_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Internal helper to carry merit calculation result
// ─────────────────────────────────────────────────────────────────────────────
class _ProgramMerit {
  final double score;
  final int maxScore;
  final String scheme;
  const _ProgramMerit({
    required this.score,
    required this.maxScore,
    required this.scheme,
  });
}

class DuPredictorService {
  final SupabaseClient _client = Supabase.instance.client;

  static List<Map<String, dynamic>>? _cachedEligibility;
  static List<Map<String, dynamic>>? _cachedBaSubjectMap;

  static const Set<String> _womensColleges = {
    'Miranda House',
    'Lady Shri Ram College for Women',
    'Gargi College',
    'Bharati College',
    'Maitreyi College',
    'Kalindi College',
    'Daulat Ram College',
    'Lakshmibai College',
    'Indraprastha College for Women',
    'Kamala Nehru College',
    'Jesus and Mary College',
    'Mata Sundri College for Women',
    'Aditi Mahavidyalaya',
    'Vivekananda College',
    'Janki Devi Memorial College',
    'Institute of Home Economics',
    'Lady Irwin College',
    'Bhagini Nivedita College',
    'Shyama Prasad Mukherji College for Women',
    'Rajguru College of Applied Sciences for Women',
    'Maharshi Valmiki College of Education',
  };

  // ─────────────────────────────────────────────────────────────────────────
  // 750-MARK PROGRAM DETECTION
  // B.Sc. science programmes where language is compulsory to appear in CUET
  // but is NOT counted in the merit. Only 3 domain subjects count (max 750).
  // ─────────────────────────────────────────────────────────────────────────
  static const Set<String> _domainOnlyKeywords = {
    'chemistry',
    'physics',
    'mathematics',
    'botany',
    'zoology',
    'biological sciences',
    'biological science',
    'biochemistry',
    'biotechnology',
    'microbiology',
    'food technology',
    'geology',
    'computer science',
    'electronics',
    'statistics',
    'instrumentation',
    'polymer science',
    'environmental science',
    'anthropology',
    'operational research',
    'home science',
    'physical education',
    'health education',
    'applied physical',
    'applied life',
    'life sciences',
  };

  bool _isDomainOnlyProgram(String programName) {
    final n = programName.toLowerCase()
        .replaceAll('.', '')
        .replaceAll('(', ' ')
        .replaceAll(')', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Must be a B.Sc. programme (hons or otherwise)
    final isBsc = n.contains('bsc') || n.startsWith('b sc');
    if (!isBsc) return false;

    return _domainOnlyKeywords.any((kw) => n.contains(kw));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MERIT SCORE CALCULATOR
  // Returns the score + scheme appropriate for this specific programme.
  // ─────────────────────────────────────────────────────────────────────────
  _ProgramMerit _computeProgramMerit({
    required String programName,
    required Map<String, double> langScores,
    required Map<String, double> domainScores,
  }) {
    if (_isDomainOnlyProgram(programName)) {
      // Domain scores only — language NOT counted
      final sorted = domainScores.values.toList()
        ..sort((a, b) => b.compareTo(a));
      final score = sorted.take(3).fold(0.0, (s, v) => s + v);
      return _ProgramMerit(
        score: score,
        maxScore: 750,
        scheme: '3 Domain Subjects Only (out of 750)\nLanguage is compulsory in CUET but NOT counted in merit',
      );
    } else {
      // Standard: best language (250) + best 3 domains (750) = 1000
      final bestLang = langScores.values.isEmpty
          ? 0.0
          : langScores.values.reduce((a, b) => a > b ? a : b);
      final sortedDomains = domainScores.values.toList()
        ..sort((a, b) => b.compareTo(a));
      final topDomains =
          sortedDomains.take(3).fold(0.0, (s, v) => s + v);
      return _ProgramMerit(
        score: bestLang + topDomains,
        maxScore: 1000,
        scheme: '1 Language (${bestLang.toInt()}) + 3 Domain Subjects out of 1000',
      );
    }
  }

  Future<void> _fetchCachesIfNeeded() async {
    if (_cachedEligibility == null) {
      final res = await _client.from('du_program_eligibility').select();
      _cachedEligibility = List<Map<String, dynamic>>.from(res);
    }
    if (_cachedBaSubjectMap == null) {
      final res = await _client.from('ba_programme_subject_map').select();
      _cachedBaSubjectMap = List<Map<String, dynamic>>.from(res);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUBJECT NORMALISER
  // ─────────────────────────────────────────────────────────────────────────
  String _normSub(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'\s*/\s*'), ' / ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PROGRAMME NAME NORMALISER
  // ─────────────────────────────────────────────────────────────────────────
  String _normProg(String name) {
    return name
        .toLowerCase()
        .replaceAll('health care', 'healthcare')
        .replaceAll('.', '')
        .replaceAll('(', ' ')
        .replaceAll(')', ' ')
        .replaceAll(RegExp(r'[\/\-,&+:\\]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMBINATION ELIGIBILITY CHECK
  // ─────────────────────────────────────────────────────────────────────────
  bool _checkCombinationEligibility(
    Map<String, dynamic> combo,
    List<String> studentLangs,
    List<String> studentDomains,
    bool studentHasGat,
  ) {
    final studentLangsNorm = studentLangs.map(_normSub).toList();
    final studentDomainsNorm = studentDomains.map(_normSub).toList();

    // Language check
    bool langOk = false;
    final langCombo = combo['languages'] as Map<String, dynamic>?;
    if (langCombo != null) {
      final count = langCombo['count'] as int? ?? 0;
      final specific = langCombo['specific'] as List<dynamic>?;
      if (specific != null && specific.isNotEmpty) {
        final specNorm = specific.map((s) => _normSub(s.toString())).toSet();
        final matched =
            studentLangsNorm.where((l) => specNorm.contains(l)).length;
        langOk = matched >= 1 && studentLangsNorm.length >= count;
      } else {
        langOk = studentLangsNorm.length >= count;
      }
    } else {
      langOk = true;
    }

    // Domain check
    bool domainOk = false;
    final domainCombo = combo['domains'] as Map<String, dynamic>?;
    if (domainCombo != null) {
      final count = domainCombo['count'] as int? ?? 0;
      final specific = domainCombo['specific'] as List<dynamic>?;
      final logic = domainCombo['logic'] as String? ?? 'any';

      if (specific == null || specific.isEmpty) {
        domainOk = studentDomainsNorm.length >= count;
      } else {
        final specNorm =
            specific.map((s) => _normSub(s.toString())).toList();
        if (logic == 'any') {
          domainOk = studentDomainsNorm.length >= count;
        } else if (logic == 'all') {
          domainOk = specNorm.every((sp) => studentDomainsNorm.contains(sp));
        } else if (logic == 'must_include') {
          final hasAll =
              specNorm.every((sp) => studentDomainsNorm.contains(sp));
          domainOk = hasAll && studentDomainsNorm.length >= count;
        } else if (logic == 'at_least_one') {
          final hasOne =
              specNorm.any((sp) => studentDomainsNorm.contains(sp));
          domainOk = hasOne && studentDomainsNorm.length >= count;
        } else {
          domainOk = studentDomainsNorm.length >= count;
        }
      }
    } else {
      domainOk = true;
    }

    // GAT check
    final needsGat = combo['general_test'] as bool? ?? false;
    final gatOk = needsGat ? studentHasGat : true;

    return langOk && domainOk && gatOk;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // B.A. PROGRAMME ROW DETECTION
  // ─────────────────────────────────────────────────────────────────────────
  bool _isBaProgrammeRow(String pName) {
    return RegExp(
      r'^B\.A\.?\s+Prog(?:ram|ramme)\s*\(',
      caseSensitive: false,
    ).hasMatch(pName.trim());
  }

  bool _studentQualifiesForBaProgramme(
    String programName,
    List<String> studentDomains,
  ) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(programName);
    if (match == null) return true;
    final parts = match.group(1)!.split('+').map((s) => s.trim()).toList();
    if (parts.length < 2) return true;
    return _isDisciplineSatisfied(parts[0], studentDomains) &&
        _isDisciplineSatisfied(parts[1], studentDomains);
  }

  bool _isDisciplineSatisfied(
      String discipline, List<String> studentDomains) {
    if (_cachedBaSubjectMap == null) return true;
    final mapRow = _cachedBaSubjectMap!.firstWhere(
      (m) => _normSub(m['discipline'].toString()) == _normSub(discipline),
      orElse: () => <String, dynamic>{},
    );
    if (mapRow.isEmpty) return true;
    final cuetSubject = mapRow['cuet_subject'];
    if (cuetSubject == null || cuetSubject.toString().isEmpty) return true;
    final cuetNorm = _normSub(cuetSubject.toString());
    return studentDomains.any((d) => _normSub(d) == cuetNorm);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FALLBACK MATCHER
  // ─────────────────────────────────────────────────────────────────────────
  String? _fallbackMatch(String cutoffName, List<String> eligibleNames) {
    final lower = cutoffName.toLowerCase();
    for (final elig in eligibleNames) {
      final eligLower = elig.toLowerCase();
      if (_normProg(elig) == _normProg(cutoffName)) return elig;
      if (lower.contains('financial investment') &&
          eligLower.contains('financial investment')) return elig;
      if (lower.contains('bachelor of management studies') &&
          eligLower.contains('bachelor of management studies')) return elig;
      if (lower.contains('elementary education') &&
          eligLower.contains('elementary education')) return elig;
      if (lower.contains('bachelor of fine arts') &&
          eligLower.contains('bachelor of fine arts')) return elig;
      if (lower.contains('five year') &&
          lower.contains('journalism') &&
          eligLower.contains('journalism')) return elig;
      if (lower.contains('information technology') &&
          lower.contains('mathematical') &&
          eligLower.contains('information technology')) return elig;
      if (lower.contains('physical education') &&
          lower.contains('health education') &&
          eligLower.contains('physical education') &&
          eligLower.contains('health education')) return elig;
      if (lower.contains('applied physical sciences') &&
          eligLower.contains('applied physical sciences')) {
        if (lower.contains('industrial') && eligLower.contains('industrial'))
          return elig;
        if (lower.contains('analytical') && eligLower.contains('analytical'))
          return elig;
        if (lower.contains('computer') && eligLower.contains('computer'))
          return elig;
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MAIN PREDICT  ─  now accepts per-subject scores
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<DuCollegeDetails>> predict({
    required Map<String, double> langScores,   // subject → score (0-250)
    required Map<String, double> domainScores, // subject → score (0-250)
    required bool studentHasGat,
    required String studentCategory,
    required String studentGender,
    String preferredDegree = 'Any',
    int year = 2025,
    bool showOutOfRange = false,
  }) async {
    try {
      if (langScores.isEmpty) {
        throw ArgumentError(
            'Please select at least one language (List A) subject.');
      }
      if (domainScores.isEmpty) {
        throw ArgumentError(
            'Please select at least one domain (List B) subject.');
      }

      final studentLanguages = langScores.keys.toList();
      final studentDomains = domainScores.keys.toList();

      // Always fetch fresh
      final eligRes = await _client.from('du_program_eligibility').select();
      _cachedEligibility = List<Map<String, dynamic>>.from(eligRes);
      final baRes = await _client.from('ba_programme_subject_map').select();
      _cachedBaSubjectMap = List<Map<String, dynamic>>.from(baRes);
      await _fetchCachesIfNeeded();

      // ── Step 1: Eligible programmes ─────────────────────────────────────
      final eligiblePrograms = <String, Map<String, dynamic>>{};
      final programDegrees = <String, String>{};
      final programNotes = <String, String>{};
      bool isBaProgrammeEligible = false;

      for (final prog in _cachedEligibility!) {
        final pName = prog['program_name'] as String;
        final degree = prog['degree'] as String? ?? '';
        final combos = prog['combinations'] as List<dynamic>? ?? [];

        bool eligible = false;
        bool hasOnlyPriority2 = true;
        String? matchedNote;

        for (final c in combos) {
          final combo = c as Map<String, dynamic>;
          if (_checkCombinationEligibility(
            combo,
            studentLanguages,
            studentDomains,
            studentHasGat,
          )) {
            eligible = true;
            if ((combo['priority'] as int? ?? 1) != 2)
              hasOnlyPriority2 = false;
            matchedNote ??= combo['note'] as String?;
          }
        }

        if (eligible) {
          eligiblePrograms[pName] = prog;
          programDegrees[pName] = degree;
          programNotes[pName] = hasOnlyPriority2
              ? 'Preference given to specific language students; you may be considered only if seats remain.'
              : (matchedNote ?? '');
          if (pName.trim() == 'B.A. (Programme)') {
            isBaProgrammeEligible = true;
          }
        }
      }

      // ── Step 2: Normalised lookup map ────────────────────────────────────
      final normToEligible = <String, String>{};
      for (final pName in eligiblePrograms.keys) {
        normToEligible[_normProg(pName)] = pName;
      }

      // ── Step 3: Fetch cutoffs (paginated) ────────────────────────────────
      final List<Map<String, dynamic>> cutoffs = [];
      int offset = 0;
      const batchSize = 1000;
      while (true) {
        final batch = await _client
            .from('du_cutoffs')
            .select()
            .eq('year', year)
            .eq('category', studentCategory)
            .range(offset, offset + batchSize - 1);
        final batchList = List<Map<String, dynamic>>.from(batch);
        cutoffs.addAll(batchList);
        if (batchList.length < batchSize) break;
        offset += batchSize;
      }

      // ── Step 4: College details ───────────────────────────────────────────
      final collegeRes = await _client.from('du_college_details').select();
      final collegeDetailsMap = <String, Map<String, dynamic>>{};
      for (final c in List<Map<String, dynamic>>.from(collegeRes)) {
        collegeDetailsMap[(c['college_name'] as String).trim().toLowerCase()] =
            c;
      }

      // ── Step 5: Match cutoff rows → eligible entries ──────────────────────
      final eligibleEntries = <String, _EligibleEntry>{};
      final isMale = studentGender.trim().toLowerCase() == 'male';

      for (final row in cutoffs) {
        final pName = (row['program_name'] as String).trim();
        final cName = (row['college_name'] as String).trim();
        final cutoffScore = (row['cutoff_score'] as num).toDouble();
        final rowGender = (row['gender'] as String? ?? 'Co-Ed').trim();
        final rowRound = row['round'] as int? ?? 1;

        if (isMale && rowGender == 'Female') continue;

        bool isRowEligible = false;
        String matchedProgramKey = '';
        String degree = 'B.A.';

        if (_isBaProgrammeRow(pName)) {
          if (isBaProgrammeEligible &&
              _studentQualifiesForBaProgramme(pName, studentDomains)) {
            isRowEligible = true;
            matchedProgramKey = 'B.A. (Programme)';
            degree = 'B.A.';
          }
        } else {
          final normCutoff = _normProg(pName);
          final exactMatch = normToEligible[normCutoff];
          if (exactMatch != null) {
            isRowEligible = true;
            matchedProgramKey = exactMatch;
            degree = programDegrees[exactMatch] ?? '';
          } else {
            final fallback = _fallbackMatch(pName, eligiblePrograms.keys.toList());
            if (fallback != null) {
              isRowEligible = true;
              matchedProgramKey = fallback;
              degree = programDegrees[fallback] ?? '';
            }
          }
        }

        if (!isRowEligible) continue;

        // Degree filter
        if (preferredDegree != 'Any' &&
            !degree.toLowerCase().contains(preferredDegree.toLowerCase())) {
          continue;
        }

        final entryKey = '$cName|||$pName';
        eligibleEntries.putIfAbsent(
          entryKey,
          () => _EligibleEntry(
            collegeName: cName,
            programName: pName,
            matchedProgramKey: matchedProgramKey,
            degree: degree,
          ),
        );
        eligibleEntries[entryKey]!.roundRows.add(
          DuRoundCutoff(round: rowRound, year: year, cutoffScore: cutoffScore),
        );
      }

      // ── Step 6: Score each entry using program-specific merit ─────────────
      final groupedByCollege = <String, List<DuProgramResult>>{};

      for (final entry in eligibleEntries.values) {
        entry.roundRows.sort((a, b) => a.cutoffScore.compareTo(b.cutoffScore));
        final bestCutoff = entry.roundRows.first.cutoffScore;

        // Calculate the correct merit score for THIS programme
        final merit = _computeProgramMerit(
          programName: entry.programName,
          langScores: langScores,
          domainScores: domainScores,
        );

        final diff = merit.score - bestCutoff;

        String chance;
        if (merit.score >= bestCutoff) {
          chance = 'Safe';
        } else if (merit.score >= bestCutoff * 0.97) {
          chance = 'Moderate';
        } else if (merit.score >= bestCutoff * 0.93) {
          chance = 'Difficult';
        } else {
          chance = 'Out of Range';
        }

        if (chance == 'Out of Range' && !showOutOfRange) continue;

        final sortedRounds = List<DuRoundCutoff>.from(entry.roundRows)
          ..sort((a, b) => a.round.compareTo(b.round));

        groupedByCollege
            .putIfAbsent(entry.collegeName, () => [])
            .add(DuProgramResult(
              programName: entry.programName,
              degree: entry.degree,
              userScore: merit.score,
              cutoffScore: bestCutoff,
              difference: double.parse(diff.toStringAsFixed(2)),
              roundCutoffs: sortedRounds,
              chance: chance,
              note: programNotes[entry.matchedProgramKey],
              maxScore: merit.maxScore,
              meritScheme: merit.scheme,
            ));
      }

      // ── Step 7: Assemble final list ───────────────────────────────────────
      final resultList = <DuCollegeDetails>[];

      groupedByCollege.forEach((cName, progs) {
        if (isMale && _womensColleges.contains(cName)) return;

        progs.sort((a, b) {
          const order = {
            'Safe': 1,
            'Moderate': 2,
            'Difficult': 3,
            'Out of Range': 4,
          };
          final d = (order[a.chance] ?? 5).compareTo(order[b.chance] ?? 5);
          return d != 0 ? d : b.difference.compareTo(a.difference);
        });

        final detailsRow = collegeDetailsMap[cName.toLowerCase()];
        resultList.add(
          detailsRow != null
              ? DuCollegeDetails.fromJson(detailsRow).copyWith(programs: progs)
              : DuCollegeDetails(collegeName: cName, programs: progs),
        );
      });

      resultList.sort((a, b) => a.collegeName.compareTo(b.collegeName));
      print('🏫 Colleges returned: ${resultList.length}');
      return resultList;
    } catch (e, stackTrace) {
      print('❌ PREDICT ERROR: $e');
      print('📍 STACK: $stackTrace');
      rethrow;
    }
  }

  // ── Utility ───────────────────────────────────────────────────────────────
  Future<List<DuCollegeCourse>> getCollegeCourses(String collegeName) async {
    final res = await _client
        .from('du_college_courses')
        .select()
        .eq('college_name', collegeName);
    return (res as List).map((c) => DuCollegeCourse.fromJson(c)).toList();
  }

  Future<List<Map<String, dynamic>>> getCutoffHistory(
    String collegeName,
  ) async {
    final res = await _client
        .from('du_cutoffs')
        .select()
        .eq('college_name', collegeName);
    return List<Map<String, dynamic>>.from(res);
  }
}

class _EligibleEntry {
  final String collegeName;
  final String programName;
  final String matchedProgramKey;
  final String degree;
  final List<DuRoundCutoff> roundRows = [];

  _EligibleEntry({
    required this.collegeName,
    required this.programName,
    required this.matchedProgramKey,
    required this.degree,
  });
}
