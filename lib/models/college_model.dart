class CollegeModel {
  final String id;
  final String name;
  final String campus;
  final String type;
  final String gender;
  final String logoUrl;
  final List<String> photos;
  final int nirfRanking;
  final List<CourseCutoff> courses;
  final String description;
  final String address;
  final List<String> rankings;
  final String nearbyMetro;
  final List<String> facilities;
  final HostelInfo? hostelInfo;
  final PlacementInfo? placementInfo;

  CollegeModel({
    required this.id,
    required this.name,
    required this.campus,
    required this.type,
    required this.gender,
    required this.logoUrl,
    this.photos = const [],
    required this.nirfRanking,
    required this.courses,
    required this.description,
    required this.address,
    this.rankings = const [],
    required this.nearbyMetro,
    this.facilities = const [],
    this.hostelInfo,
    this.placementInfo,
  });
}

class HostelInfo {
  final String fee;
  final String details;
  final List<String> facilities;

  HostelInfo({
    required this.fee,
    required this.details,
    this.facilities = const [],
  });
}

class PlacementInfo {
  final double placementPercentage;
  final String highestPackage;
  final String averagePackage;

  PlacementInfo({
    required this.placementPercentage,
    required this.highestPackage,
    required this.averagePackage,
  });
}

class CourseCutoff {
  final String courseName;
  final List<String> courseCombination;
  final Map<String, CategoryCutoff> cutoffs; // Key is category like 'General', 'OBC'
  final String fee;
  final String duration;
  
  CourseCutoff({
    required this.courseName,
    this.courseCombination = const [],
    required this.cutoffs,
    required this.fee,
    required this.duration,
  });
}

class CategoryCutoff {
  final double round1;
  final double round2;
  final double round3;
  final double expected2026;
  final double? previousYear; // Optional now, since schema only requires expected_2026 and rounds

  CategoryCutoff({
    required this.round1,
    required this.round2,
    required this.round3,
    required this.expected2026,
    this.previousYear,
  });
}

// User Score Model to pass around
class UserScore {
  double english;
  double domain1;
  double domain2;
  double domain3;
  double generalTest;
  String category;
  String gender;

  UserScore({
    this.english = 0,
    this.domain1 = 0,
    this.domain2 = 0,
    this.domain3 = 0,
    this.generalTest = 0,
    this.category = 'General',
    this.gender = 'Male',
  });

  double getTotalScore(bool includeGT) {
    if (includeGT) {
      // Logic varies, but for simplicity let's say total is out of 800 (Lang + 3 domains) or include GT out of 850
      return english + domain1 + domain2 + domain3 + generalTest;
    }
    return english + domain1 + domain2 + domain3; // Out of 800
  }
}
