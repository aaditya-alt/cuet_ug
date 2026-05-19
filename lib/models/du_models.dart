class UserCuetSubject {
  final String name; // exact subject name from cuet_subject_lists
  final String list; // 'A' or 'B' or 'General Test'
  final double score; // out of 250 (normalized CUET score)

  UserCuetSubject({
    required this.name,
    required this.list,
    required this.score,
  });
}

class DuProgramResult {
  final String programName;
  final String degree; // e.g. 'B.Sc.'
  final double userScore; // merit score for THIS specific program
  final double cutoffScore; // the cutoff from du_cutoffs
  final double difference; // userScore - cutoffScore
  final List<DuRoundCutoff> roundCutoffs; // all rounds' data for this program
  final double? originalScore; // raw score before scaling (e.g. 500)
  final int? originalTotal; // raw total before scaling (e.g. 750)
  final bool isScaled; // whether the score was scaled to 1000
  final String chance; // Safe / Moderate / Difficult / Out of Range
  final String? note; // Priority note or other details

  // Merit scheme fields — explain HOW the score was computed for this program
  final int maxScore;       // 750 or 1000 depending on program type
  final String meritScheme; // human-readable explanation for the student

  DuProgramResult({
    required this.programName,
    required this.degree,
    required this.userScore,
    required this.cutoffScore,
    required this.difference,
    required this.roundCutoffs,
    this.originalScore,
    this.originalTotal,
    this.isScaled = false,
    this.chance = 'Safe',
    this.note,
    this.maxScore = 1000,
    this.meritScheme = '1 Language + 3 Domain Subjects',
  });
}

class DuRoundCutoff {
  final int round;
  final int year;
  final double cutoffScore;

  DuRoundCutoff({
    required this.round,
    required this.year,
    required this.cutoffScore,
  });
}

class DuCollegeDetails {
  final int id;
  final String collegeName;
  final int? established;
  final String? campusType;
  final String? address;
  final String? nearestMetro;
  final String? mainImageUrl;
  final List<String> extraImages;
  final String? website;
  final String? principal;
  final String? affiliation;
  final String? naacGrade;
  final int? nirfRanking;
  final int? nirfYear;
  final List<String> facilities;
  final bool hostelAvailable;
  final String? hostelType;
  final Map<String, dynamic>? hostelFees;
  final List<String> hostelAmenities;
  final double? placementAvg;
  final double? placementHighest;
  final double? placementPercent;
  final int? placementYear;
  final List<dynamic>? notableAlumni;
  final String? description;
  
  // Predictor specific fields
  final List<DuProgramResult> programs;
  final String? logoUrl;

  DuCollegeDetails({
    this.id = 0,
    required this.collegeName,
    this.established,
    this.campusType,
    this.address,
    this.nearestMetro,
    this.mainImageUrl,
    this.extraImages = const [],
    this.website,
    this.principal,
    this.affiliation,
    this.naacGrade,
    this.nirfRanking,
    this.nirfYear,
    this.facilities = const [],
    this.hostelAvailable = false,
    this.hostelType,
    this.hostelFees,
    this.hostelAmenities = const [],
    this.placementAvg,
    this.placementHighest,
    this.placementPercent,
    this.placementYear,
    this.notableAlumni,
    this.description,
    this.programs = const [],
    this.logoUrl,
  });

  DuCollegeDetails copyWith({
    int? id,
    String? collegeName,
    int? established,
    String? campusType,
    String? address,
    String? nearestMetro,
    String? mainImageUrl,
    List<String>? extraImages,
    String? website,
    String? principal,
    String? affiliation,
    String? naacGrade,
    int? nirfRanking,
    int? nirfYear,
    List<String>? facilities,
    bool? hostelAvailable,
    String? hostelType,
    Map<String, dynamic>? hostelFees,
    List<String>? hostelAmenities,
    double? placementAvg,
    double? placementHighest,
    double? placementPercent,
    int? placementYear,
    List<dynamic>? notableAlumni,
    String? description,
    List<DuProgramResult>? programs,
    String? logoUrl,
  }) {
    return DuCollegeDetails(
      id: id ?? this.id,
      collegeName: collegeName ?? this.collegeName,
      established: established ?? this.established,
      campusType: campusType ?? this.campusType,
      address: address ?? this.address,
      nearestMetro: nearestMetro ?? this.nearestMetro,
      mainImageUrl: mainImageUrl ?? this.mainImageUrl,
      extraImages: extraImages ?? this.extraImages,
      website: website ?? this.website,
      principal: principal ?? this.principal,
      affiliation: affiliation ?? this.affiliation,
      naacGrade: naacGrade ?? this.naacGrade,
      nirfRanking: nirfRanking ?? this.nirfRanking,
      nirfYear: nirfYear ?? this.nirfYear,
      facilities: facilities ?? this.facilities,
      hostelAvailable: hostelAvailable ?? this.hostelAvailable,
      hostelType: hostelType ?? this.hostelType,
      hostelFees: hostelFees ?? this.hostelFees,
      hostelAmenities: hostelAmenities ?? this.hostelAmenities,
      placementAvg: placementAvg ?? this.placementAvg,
      placementHighest: placementHighest ?? this.placementHighest,
      placementPercent: placementPercent ?? this.placementPercent,
      placementYear: placementYear ?? this.placementYear,
      notableAlumni: notableAlumni ?? this.notableAlumni,
      description: description ?? this.description,
      programs: programs ?? this.programs,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  factory DuCollegeDetails.fromJson(Map<String, dynamic> json) {
    return DuCollegeDetails(
      id: json['id'] as int? ?? 0,
      collegeName: json['college_name'] as String? ?? json['name'] as String? ?? '',
      established: json['established'] as int?,
      campusType: json['campus_type'] as String?,
      address: json['address'] as String?,
      nearestMetro: json['nearest_metro'] as String?,
      mainImageUrl: json['main_image_url'] as String?,
      extraImages: (json['extra_images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      website: json['website'] as String?,
      principal: json['principal'] as String?,
      affiliation: json['affiliation'] as String?,
      naacGrade: json['naac_grade'] as String?,
      nirfRanking: json['nirf_ranking'] as int?,
      nirfYear: json['nirf_year'] as int?,
      facilities: (json['facilities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      hostelAvailable: json['hostel_available'] as bool? ?? false,
      hostelType: json['hostel_type'] as String?,
      hostelFees: json['hostel_fees'] as Map<String, dynamic>?,
      hostelAmenities: (json['hostel_amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      placementAvg: (json['placement_avg'] as num?)?.toDouble(),
      placementHighest: (json['placement_highest'] as num?)?.toDouble(),
      placementPercent: (json['placement_percent'] as num?)?.toDouble(),
      placementYear: json['placement_year'] as int?,
      notableAlumni: json['notable_alumni'] as List<dynamic>?,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
    );
  }
}

// Alias for backward compatibility with screens using DuCollegeData
typedef DuCollegeData = DuCollegeDetails;

class DuCollegeCourse {
  final int id;
  final String collegeName;
  final String courseName;
  final String? duration;
  final String? fees;
  final String? eligibility;

  DuCollegeCourse({
    required this.id,
    required this.collegeName,
    required this.courseName,
    this.duration,
    this.fees,
    this.eligibility,
  });

  factory DuCollegeCourse.fromJson(Map<String, dynamic> json) {
    return DuCollegeCourse(
      id: json['id'] as int? ?? 0,
      collegeName: json['college_name'] as String? ?? '',
      courseName: json['course_name'] as String? ?? '',
      duration: json['duration'] as String?,
      fees: json['fees'] as String?,
      eligibility: json['eligibility'] as String?,
    );
  }
}

class DuPreferenceSheet {
  final String id;
  final String? userId;
  final String userName;
  final String userEmail;
  final List<String> targetCourses;
  final String campusPreference;
  final String priorityFactor;
  final List<Map<String, dynamic>> sheetData;
  final DateTime createdAt;

  DuPreferenceSheet({
    required this.id,
    this.userId,
    required this.userName,
    required this.userEmail,
    required this.targetCourses,
    required this.campusPreference,
    required this.priorityFactor,
    required this.sheetData,
    required this.createdAt,
  });

  factory DuPreferenceSheet.fromJson(Map<String, dynamic> json) {
    return DuPreferenceSheet(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String? ?? 'Anonymous',
      userEmail: json['user_email'] as String? ?? 'No email',
      targetCourses: (json['target_courses'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      campusPreference: json['campus_preference'] as String? ?? 'Balanced',
      priorityFactor: json['priority_factor'] as String? ?? 'Balanced',
      sheetData: (json['sheet_data'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'target_courses': targetCourses,
      'campus_preference': campusPreference,
      'priority_factor': priorityFactor,
      'sheet_data': sheetData,
    };
  }
}
