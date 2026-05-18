import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/du_models.dart';

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
  // Used for ALL subject comparisons (eligibility specific[], student input,
  // BA programme map). One function everywhere = no mismatch possible.
  //
  // Rules:
  //   • lowercase
  //   • normalise spaces around "/" → single space each side
  //   • collapse all other whitespace
  //   • trim
  //
  // Examples:
  //   "Mathematics / Applied Mathematics" → "mathematics / applied mathematics"
  //   "mathematics/applied mathematics"   → "mathematics / applied mathematics"
  //   "Physics"                           → "physics"
  //   "Biology / Biological Studies / Biotechnology / Biochemistry"
  //     → "biology / biological studies / biotechnology / biochemistry"
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
  // Used only for cutoff ↔ eligibility table name matching.
  // Strips dots, brackets, separators so "B.Sc. (Hons.)" == "B.Sc (Hons)"
  // ─────────────────────────────────────────────────────────────────────────
  String _normProg(String name) {
    return name
        .toLowerCase()
        .replaceAll('health care', 'healthcare') // ADD THIS LINE
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

    // ── Language check ──────────────────────────────────────────
    bool langOk = false;
    final langCombo = combo['languages'] as Map<String, dynamic>?;
    if (langCombo != null) {
      final count = langCombo['count'] as int? ?? 0;
      final specific = langCombo['specific'] as List<dynamic>?;
      if (specific != null && specific.isNotEmpty) {
        final specNorm = specific.map((s) => _normSub(s.toString())).toSet();
        final matched = studentLangsNorm
            .where((l) => specNorm.contains(l))
            .length;
        langOk = matched >= 1 && studentLangsNorm.length >= count;
      } else {
        langOk = studentLangsNorm.length >= count;
      }
    } else {
      langOk = true;
    }

    // ── Domain check ────────────────────────────────────────────
    bool domainOk = false;
    final domainCombo = combo['domains'] as Map<String, dynamic>?;
    if (domainCombo != null) {
      final count = domainCombo['count'] as int? ?? 0;
      final specific = domainCombo['specific'] as List<dynamic>?;
      final logic = domainCombo['logic'] as String? ?? 'any';

      if (specific == null || specific.isEmpty) {
        domainOk = studentDomainsNorm.length >= count;
      } else {
        final specNorm = specific.map((s) => _normSub(s.toString())).toList();

        if (logic == 'any') {
          domainOk = studentDomainsNorm.length >= count;
        } else if (logic == 'all') {
          domainOk = specNorm.every((sp) => studentDomainsNorm.contains(sp));
        } else if (logic == 'must_include') {
          final hasAll = specNorm.every(
            (sp) => studentDomainsNorm.contains(sp),
          );
          domainOk = hasAll && studentDomainsNorm.length >= count;
          print(
            'must_include | specNorm=$specNorm | hasAll=$hasAll | studentLen=${studentDomainsNorm.length} | count=$count | domainOk=$domainOk',
          );
        } else if (logic == 'at_least_one') {
          final hasOne = specNorm.any((sp) => studentDomainsNorm.contains(sp));
          domainOk = hasOne && studentDomainsNorm.length >= count;
        } else {
          domainOk = studentDomainsNorm.length >= count;
        }
      }
    } else {
      domainOk = true;
    }

    // ── GAT check ───────────────────────────────────────────────
    final needsGat = combo['general_test'] as bool? ?? false;
    final gatOk = needsGat ? studentHasGat : true;

    return langOk && domainOk && gatOk;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // B.A. PROGRAMME ROW DETECTION
  // Matches "B.A Program (...)" or "B.A. Programme (...)"
  // but NOT "B.A. (Programme)" or "B.A. (Hons.) ..."
  // ─────────────────────────────────────────────────────────────────────────
  bool _isBaProgrammeRow(String pName) {
    return RegExp(
      r'^B\.A\.?\s+Prog(?:ram|ramme)\s*\(',
      caseSensitive: false,
    ).hasMatch(pName.trim());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // B.A. PROGRAMME COMBINATION CHECK
  // Parses "B.A Program (Discipline1 + Discipline2)" and checks both
  // disciplines against the student's CUET domains via ba_programme_subject_map
  // ─────────────────────────────────────────────────────────────────────────
  bool _studentQualifiesForBaProgramme(
    String programName,
    List<String> studentDomains,
  ) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(programName);
    if (match == null) return true; // no brackets → generic row → pass

    final parts = match.group(1)!.split('+').map((s) => s.trim()).toList();
    if (parts.length < 2) return true;

    return _isDisciplineSatisfied(parts[0], studentDomains) &&
        _isDisciplineSatisfied(parts[1], studentDomains);
  }

  bool _isDisciplineSatisfied(String discipline, List<String> studentDomains) {
    if (_cachedBaSubjectMap == null) return true;

    // Find discipline in map using _normSub for consistent comparison
    final mapRow = _cachedBaSubjectMap!.firstWhere(
      (m) => _normSub(m['discipline'].toString()) == _normSub(discipline),
      orElse: () => <String, dynamic>{},
    );

    if (mapRow.isEmpty) return true; // not in map → college-internal → pass

    final cuetSubject = mapRow['cuet_subject'];
    if (cuetSubject == null || cuetSubject.toString().isEmpty) {
      return true; // null CUET subject → college-internal → pass
    }

    // Compare using _normSub on both sides
    final cuetNorm = _normSub(cuetSubject.toString());
    return studentDomains.any((d) => _normSub(d) == cuetNorm);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FALLBACK MATCHER
  // Only called when _normProg() exact lookup fails.
  // Handles specific known edge-cases without fuzzy matching.
  // ─────────────────────────────────────────────────────────────────────────
  String? _fallbackMatch(String cutoffName, List<String> eligibleNames) {
    final lower = cutoffName.toLowerCase();

    for (final elig in eligibleNames) {
      final eligLower = elig.toLowerCase();

      // Re-try normalised match (redundant but safe)
      if (_normProg(elig) == _normProg(cutoffName)) return elig;

      // BBA-FIA
      if (lower.contains('financial investment') &&
          eligLower.contains('financial investment'))
        return elig;

      // BMS
      if (lower.contains('bachelor of management studies') &&
          eligLower.contains('bachelor of management studies'))
        return elig;

      // B.El.Ed.
      if (lower.contains('elementary education') &&
          eligLower.contains('elementary education'))
        return elig;

      // BFA
      if (lower.contains('bachelor of fine arts') &&
          eligLower.contains('bachelor of fine arts'))
        return elig;

      // Five Year Journalism
      if (lower.contains('five year') &&
          lower.contains('journalism') &&
          eligLower.contains('journalism'))
        return elig;

      // B.Tech IT & MI
      if (lower.contains('information technology') &&
          lower.contains('mathematical') &&
          eligLower.contains('information technology'))
        return elig;

      // B.Sc. Physical Education, Health Education and Sports
      if (lower.contains('physical education') &&
          lower.contains('health education') &&
          eligLower.contains('physical education') &&
          eligLower.contains('health education'))
        return elig;

      // B.Sc. Applied Physical Sciences (disambiguate by secondary keyword)
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
  // MAIN PREDICT
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<DuCollegeDetails>> predict({
    required List<String> studentLanguages,
    required List<String> studentDomains,
    required bool studentHasGat,
    required double studentScore,
    required String studentCategory,
    required String studentGender,
    String preferredDegree = 'Any',
    int year = 2025,
    bool showOutOfRange = false,
  }) async {
    try {
      if (studentScore <= 0) {
        throw ArgumentError('Student score must be greater than zero.');
      }
      if (studentLanguages.isEmpty) {
        throw ArgumentError('Please select at least one language from List A.');
      }
      if (studentDomains.isEmpty) {
        throw ArgumentError(
          'Please select at least one domain subject from List B.',
        );
      }

      // With this — fetch directly, no caching at all:
      final eligRes = await _client.from('du_program_eligibility').select();
      _cachedEligibility = List<Map<String, dynamic>>.from(eligRes);

      final baRes = await _client.from('ba_programme_subject_map').select();
      _cachedBaSubjectMap = List<Map<String, dynamic>>.from(baRes);

      // Also print what the eligibility table has for Chemistry

      await _fetchCachesIfNeeded();

      // ── Step 1: Which programmes is this student eligible for? ────────────
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
            if ((combo['priority'] as int? ?? 1) != 2) hasOnlyPriority2 = false;
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

      print('📋 Eligible programs: ${eligiblePrograms.length}');

      // ── Step 2: Build normalised name → original name lookup ─────────────
      final normToEligible = <String, String>{};
      for (final pName in eligiblePrograms.keys) {
        normToEligible[_normProg(pName)] = pName;
      }

      // ── Step 3: Fetch cutoff rows ─────────────────────────────────────────
      final cutoffsRes = await _client
          .from('du_cutoffs')
          .select()
          .eq('year', year)
          .eq('category', studentCategory)
          .limit(3000);

      // Replace the single cutoffs fetch with this:
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

        if (batchList.length < batchSize) break; // last batch
        offset += batchSize;
      }

      // ── Step 4: College details lookup ───────────────────────────────────
      final collegeRes = await _client.from('du_college_details').select();
      final collegeDetailsMap = <String, Map<String, dynamic>>{};
      for (final c in List<Map<String, dynamic>>.from(collegeRes)) {
        collegeDetailsMap[(c['college_name'] as String).trim().toLowerCase()] =
            c;
      }

      // ── Step 5: Match every cutoff row ────────────────────────────────────
      final eligibleEntries = <String, _EligibleEntry>{};
      final isMale = studentGender.trim().toLowerCase() == 'male';
      int skippedGender = 0, skippedNoMatch = 0, matchedCount = 0;

      for (final row in cutoffs) {
        final pName = (row['program_name'] as String).trim();
        final cName = (row['college_name'] as String).trim();
        final cutoffScore = (row['cutoff_score'] as num).toDouble();
        final rowGender = (row['gender'] as String? ?? 'Co-Ed').trim();
        final rowRound = row['round'] as int? ?? 1;

        // Gender filter — DB stores 'Female' for women's colleges
        if (isMale && rowGender == 'Female') {
          skippedGender++;
          continue;
        }

        bool isRowEligible = false;
        String matchedProgramKey = '';
        String degree = 'B.A.';

        if (_isBaProgrammeRow(pName)) {
          // B.A Program (Disc1 + Disc2) rows
          if (isBaProgrammeEligible &&
              _studentQualifiesForBaProgramme(pName, studentDomains)) {
            isRowEligible = true;
            matchedProgramKey = 'B.A. (Programme)';
            degree = 'B.A.';
          }
        } else {
          // Lookup 1: exact normalised match
          final normCutoff = _normProg(pName);
          final exactMatch = normToEligible[normCutoff];

          if (exactMatch != null) {
            isRowEligible = true;
            matchedProgramKey = exactMatch;
            degree = programDegrees[exactMatch] ?? '';
          } else {
            // Lookup 2: targeted fallback for known edge-cases
            final fallback = _fallbackMatch(
              pName,
              eligiblePrograms.keys.toList(),
            );
            if (fallback != null) {
              isRowEligible = true;
              matchedProgramKey = fallback;
              degree = programDegrees[fallback] ?? '';
            } else {
              // print('❌ NO MATCH: "$pName"  norm:"$normCutoff"');
            }
          }
        }

        if (!isRowEligible) {
          skippedNoMatch++;
          continue;
        }

        matchedCount++;

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

      // print(
      //   '📈 matched=$matchedCount skippedGender=$skippedGender skippedNoMatch=$skippedNoMatch',
      // );

      // ── Step 6: Score each entry ──────────────────────────────────────────
      final groupedByCollege = <String, List<DuProgramResult>>{};

      for (final entry in eligibleEntries.values) {
        entry.roundRows.sort((a, b) => a.cutoffScore.compareTo(b.cutoffScore));
        final bestCutoff = entry.roundRows.first.cutoffScore;
        final diff = studentScore - bestCutoff;

        String chance;
        if (studentScore >= bestCutoff) {
          chance = 'Safe';
        } else if (studentScore >= bestCutoff * 0.97) {
          chance = 'Moderate';
        } else if (studentScore >= bestCutoff * 0.93) {
          chance = 'Difficult';
        } else {
          chance = 'Out of Range';
        }

        if (chance == 'Out of Range' && !showOutOfRange) continue;

        final sortedRounds = List<DuRoundCutoff>.from(entry.roundRows)
          ..sort((a, b) => a.round.compareTo(b.round));

        groupedByCollege
            .putIfAbsent(entry.collegeName, () => [])
            .add(
              DuProgramResult(
                programName: entry.programName,
                degree: entry.degree,
                userScore: studentScore,
                cutoffScore: bestCutoff,
                difference: double.parse(diff.toStringAsFixed(2)),
                roundCutoffs: sortedRounds,
                chance: chance,
                note: programNotes[entry.matchedProgramKey],
              ),
            );
      }

      // ── Step 7: Assemble final list ───────────────────────────────────────
      final resultList = <DuCollegeDetails>[];

      groupedByCollege.forEach((cName, progs) {
        // Double-guard: skip women's colleges for male students
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

  // ── Utility methods ───────────────────────────────────────────────────────
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
