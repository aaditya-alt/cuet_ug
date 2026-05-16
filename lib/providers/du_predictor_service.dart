import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/du_models.dart';

class DuPredictorService {
  final SupabaseClient _client = Supabase.instance.client;

  List<Map<String, dynamic>>? _cachedPrograms;

  Future<void> _fetchCachesIfNeeded() async {
    if (_cachedPrograms == null) {
      final res = await _client.from('du_program_eligibility').select();
      _cachedPrograms = List<Map<String, dynamic>>.from(res);
    }
  }

  bool _checkComboEligibility(
    Map<String, dynamic> combo,
    List<UserCuetSubject> userSubjects,
  ) {
    final userListA = userSubjects
        .where((s) => s.list.toUpperCase().contains('A'))
        .toList();
    final userListB = userSubjects
        .where((s) => s.list.toUpperCase().contains('B'))
        .toList();
    final hasGT = userSubjects.any(
      (s) =>
          s.list.toUpperCase().contains('GENERAL') ||
          s.list.toUpperCase() == 'GAT' ||
          s.name.toLowerCase().contains('general test'),
    );

    // 1. Languages Check
    final languages = combo['languages'] as Map<String, dynamic>?;
    if (languages != null) {
      final reqCount = languages['count'] as int? ?? 0;
      final specific = languages['specific'] as List<dynamic>?;

      if (userListA.length < reqCount) return false;

      if (specific != null && specific.isNotEmpty) {
        bool allFound = true;
        for (final sp in specific) {
          if (!userListA.any((u) => u.name == sp)) {
            allFound = false;
            break;
          }
        }
        if (!allFound) return false;
      }
    }

    // 2. Domains Check
    final domains = combo['domains'] as Map<String, dynamic>?;
    if (domains != null) {
      final reqCount = domains['count'] as int? ?? 0;
      final specific = domains['specific'] as List<dynamic>?;
      final logic = domains['logic'] as String? ?? 'all';
      final additional = domains['additional'] as List<dynamic>?;
      final additionalLogic =
          domains['additional_logic'] as String? ?? 'at_least_one';

      if (userListB.length < reqCount) return false;

      if (specific != null && specific.isNotEmpty) {
        int matched = 0;
        for (final sp in specific) {
          if (userListB.any((u) => u.name == sp)) matched++;
        }
        if (logic == 'all' && matched < specific.length) return false;
        if (logic == 'at_least_one' && matched == 0) return false;
      }

      if (additional != null && additional.isNotEmpty) {
        int matched = 0;
        for (final add in additional) {
          if (userListB.any((u) => u.name == add)) matched++;
        }
        if (additionalLogic == 'at_least_one' && matched == 0) return false;
      }
    }

    // 3. General Test Check
    final needsGT = combo['general_test'] as bool? ?? false;
    if (needsGT && !hasGT) return false;

    return true;
  }

  _ScoreDetail _calculateDetailedScore(
    Map<String, dynamic> combo,
    List<UserCuetSubject> userSubjects,
  ) {
    double total = 0.0;
    final List<UserCuetSubject> remaining = List.from(userSubjects);

    // 1. Language Score
    final languages = combo['languages'] as Map<String, dynamic>?;
    if (languages != null) {
      final count = languages['count'] as int? ?? 0;
      final specific = languages['specific'] as List<dynamic>?;
      final userListA = remaining
          .where((s) => s.list.toUpperCase().contains('A'))
          .toList();
      userListA.sort((a, b) => b.score.compareTo(a.score));

      int taken = 0;
      if (specific != null && specific.isNotEmpty) {
        for (final sp in specific) {
          final found = userListA.where((u) => u.name == sp).firstOrNull;
          if (found != null) {
            total += found.score;
            remaining.remove(found);
            taken++;
          }
        }
      }

      final availableA = remaining
          .where((s) => s.list.toUpperCase().contains('A'))
          .toList();
      availableA.sort((a, b) => b.score.compareTo(a.score));
      for (int i = 0; i < (count - taken) && i < availableA.length; i++) {
        total += availableA[i].score;
        remaining.remove(availableA[i]);
      }
    }

    // 2. Domain Score
    final domains = combo['domains'] as Map<String, dynamic>?;
    if (domains != null) {
      final count = domains['count'] as int? ?? 0;
      final specific = domains['specific'] as List<dynamic>?;
      final logic = domains['logic'] as String? ?? 'all';
      final additional = domains['additional'] as List<dynamic>?;
      final userListB = remaining
          .where((s) => s.list.toUpperCase().contains('B'))
          .toList();
      userListB.sort((a, b) => b.score.compareTo(a.score));

      int taken = 0;
      if (specific != null && specific.isNotEmpty) {
        if (logic == 'all') {
          for (final sp in specific) {
            final found = userListB.where((u) => u.name == sp).firstOrNull;
            if (found != null) {
              total += found.score;
              remaining.remove(found);
              taken++;
            }
          }
        } else if (logic == 'at_least_one') {
          userListB.sort((a, b) => b.score.compareTo(a.score));
          for (final b in userListB) {
            if (specific.contains(b.name)) {
              total += b.score;
              remaining.remove(b);
              taken++;
              break;
            }
          }
        }
      }

      if (additional != null && additional.isNotEmpty) {
        final availableB = remaining
            .where((s) => s.list.toUpperCase().contains('B'))
            .toList();
        availableB.sort((a, b) => b.score.compareTo(a.score));
        for (final add in additional) {
          final found = availableB.where((u) => u.name == add).firstOrNull;
          if (found != null) {
            total += found.score;
            remaining.remove(found);
            taken++;
            break;
          }
        }
      }

      final availableB = remaining
          .where((s) => s.list.toUpperCase().contains('B'))
          .toList();
      availableB.sort((a, b) => b.score.compareTo(a.score));
      for (int i = 0; i < (count - taken) && i < availableB.length; i++) {
        total += availableB[i].score;
        remaining.remove(availableB[i]);
      }
    }

    // 3. General Test Score
    final needsGT = combo['general_test'] as bool? ?? false;
    if (needsGT) {
      final gt = userSubjects
          .where(
            (s) =>
                s.list.toUpperCase().contains('GENERAL') ||
                s.list.toUpperCase() == 'GAT' ||
                s.name.toLowerCase().contains('general test'),
          )
          .firstOrNull;
      if (gt != null) total += gt.score;
    }

    int totalReq = 0;
    if (languages != null) totalReq += languages['count'] as int;
    if (domains != null) totalReq += domains['count'] as int;
    if (needsGT) totalReq += 1;

    double scaledScore = total;
    bool isScaled = false;

    if (totalReq > 0) {
      // Scale based on the requirement of the course
      scaledScore = (total / (totalReq * 250)) * 1000;
      if (totalReq != 4) isScaled = true;
    }

    return _ScoreDetail(
      scaledScore: scaledScore,
      rawScore: total,
      totalSubjects: totalReq,
      isScaled: isScaled,
    );
  }

  Future<List<DuCollegeDetails>> predict({
    required String category,
    required int round,
    required int year,
    required List<UserCuetSubject> userSubjects,
    required String gender,
  }) async {
    await _fetchCachesIfNeeded();

    final programBestScoreMap = <String, double>{};
    final programBestDetailMap = <String, _ScoreDetail>{};
    final eligibleProgramNames = <String>[];

    for (final prog in _cachedPrograms!) {
      final pName = prog['program_name'] as String;
      final combos = prog['combinations'] as List<dynamic>;

      double bestScaledForThisProg = -1.0;
      _ScoreDetail? bestDetail;

      for (final c in combos) {
        final combo = c as Map<String, dynamic>;
        if (_checkComboEligibility(combo, userSubjects)) {
          final detail = _calculateDetailedScore(combo, userSubjects);
          if (detail.scaledScore > bestScaledForThisProg) {
            bestScaledForThisProg = detail.scaledScore;
            bestDetail = detail;
          }
        }
      }

      if (bestScaledForThisProg >= 0 && bestDetail != null) {
        programBestScoreMap[pName] = bestScaledForThisProg;
        programBestDetailMap[pName] = bestDetail;
        eligibleProgramNames.add(pName);
      }
    }

    if (eligibleProgramNames.isEmpty) return [];

    // Fetch cutoffs
    final cutoffsRes = await _client
        .from('du_cutoffs')
        .select()
        .eq('category', category)
        .eq('year', year)
        .inFilter('program_name', eligibleProgramNames);

    final List<Map<String, dynamic>> allCutoffs =
        List<Map<String, dynamic>>.from(cutoffsRes);

    // Fetch college details (Inner Join logic)
    final collegeRes = await _client.from('du_college_details').select();
    final List<Map<String, dynamic>> allCollegesInfo =
        List<Map<String, dynamic>>.from(collegeRes);

    final groupedByCollege = <String, List<DuProgramResult>>{};

    for (final row in allCutoffs) {
      final pName = row['program_name'] as String;
      final cName = row['college_name'] as String;
      final rowRound = row['round'] as int;
      final rowScore = (row['cutoff_score'] as num).toDouble();

      // Gender filtering
      final genderConstraint = row['gender'] as String?;
      if (gender == 'Male' && genderConstraint == 'Female') continue;

      if (rowRound == round) {
        final progInfo = _cachedPrograms!.firstWhere(
          (p) => p['program_name'] == pName,
        );
        final degree = progInfo['degree'] as String? ?? '';
        final detail = programBestDetailMap[pName]!;
        final userScore = detail.scaledScore;
        final diff = userScore - rowScore;

        // Hide programs where user score is more than 5 marks below cutoff
        if (diff < -5) continue;

        final roundHistory = allCutoffs
            .where(
              (c) => c['program_name'] == pName && c['college_name'] == cName,
            )
            .map(
              (c) => DuRoundCutoff(
                round: c['round'] as int,
                year: c['year'] as int,
                cutoffScore: (c['cutoff_score'] as num).toDouble(),
              ),
            )
            .toList();
        roundHistory.sort((a, b) => a.round.compareTo(b.round));

        final result = DuProgramResult(
          programName: pName,
          degree: degree,
          userScore: userScore,
          cutoffScore: rowScore,
          difference: diff,
          roundCutoffs: roundHistory,
          originalScore: detail.rawScore,
          originalTotal: detail.totalSubjects * 250,
          isScaled: detail.isScaled,
        );

        if (!groupedByCollege.containsKey(cName)) {
          groupedByCollege[cName] = [];
        }
        groupedByCollege[cName]!.add(result);
      }
    }

    final resultList = <DuCollegeDetails>[];
    groupedByCollege.forEach((cName, progs) {
      final collegeInfo = allCollegesInfo
          .where((c) => c['college_name'] == cName)
          .firstOrNull;
      if (collegeInfo != null) {
        progs.sort((a, b) => b.difference.compareTo(a.difference));
        resultList.add(
          DuCollegeDetails.fromJson(collegeInfo).copyWith(programs: progs),
        );
      }
    });

    resultList.sort((a, b) => a.collegeName.compareTo(b.collegeName));
    return resultList;
  }

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

class _ScoreDetail {
  final double scaledScore;
  final double rawScore;
  final int totalSubjects;
  final bool isScaled;

  _ScoreDetail({
    required this.scaledScore,
    required this.rawScore,
    required this.totalSubjects,
    required this.isScaled,
  });
}
