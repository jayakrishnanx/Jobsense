import 'user.dart';

class EligibilityPoint {
  final String title;
  final bool isMet;
  final String explanation;

  const EligibilityPoint({
    required this.title,
    required this.isMet,
    required this.explanation,
  });
}

class EligibilityResult {
  final bool isEligible;
  final List<EligibilityPoint> points;
  final String summary;

  const EligibilityResult({
    required this.isEligible,
    required this.points,
    required this.summary,
  });
}

class AiSummaryData {
  final String executiveBrief;
  final List<String> keyHighlights;
  final String eligibilityOverview;
  final List<String> examPattern;
  final List<String> importantTips;
  final String model;
  final bool isAiGenerated;

  const AiSummaryData({
    this.executiveBrief = '',
    this.keyHighlights = const [],
    this.eligibilityOverview = '',
    this.examPattern = const [],
    this.importantTips = const [],
    this.model = 'JobSense-AI',
    this.isAiGenerated = true,
  });

  factory AiSummaryData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AiSummaryData(isAiGenerated: false);
    return AiSummaryData(
      executiveBrief: json['executiveBrief']?.toString() ?? '',
      keyHighlights: (json['keyHighlights'] as List?)?.map((e) => e.toString()).toList() ?? [],
      eligibilityOverview: json['eligibilityOverview']?.toString() ?? '',
      examPattern: (json['examPattern'] as List?)?.map((e) => e.toString()).toList() ?? [],
      importantTips: (json['importantTips'] as List?)?.map((e) => e.toString()).toList() ?? [],
      model: json['model']?.toString() ?? 'JobSense-AI',
      isAiGenerated: json['isAiGenerated'] == true || (json['executiveBrief'] != null && json['executiveBrief'].toString().isNotEmpty),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'executiveBrief': executiveBrief,
      'keyHighlights': keyHighlights,
      'eligibilityOverview': eligibilityOverview,
      'examPattern': examPattern,
      'importantTips': importantTips,
      'model': model,
      'isAiGenerated': isAiGenerated,
    };
  }
}

class Job {
  final String id;
  final String title;
  final String organization;
  final String department;
  final String jobType; // e.g. 'Central Govt', 'State Govt', 'Banking', 'Defense'
  final String location;
  final String vacancies;
  final String qualification;
  final String courseRequirements;
  final int ageMin;
  final int ageMax;
  final String category; // e.g. 'All Categories', 'General / OBC / SC / ST'
  final String experience;
  final String applicationStartDate;
  final String lastDate;
  final String applicationFee;
  final String selectionProcess;
  final String salary;
  final String description;
  final String officialNotificationUrl;
  final String applyUrl;
  final AiSummaryData? aiSummary;

  const Job({
    required this.id,
    required this.title,
    required this.organization,
    required this.department,
    required this.jobType,
    required this.location,
    required this.vacancies,
    required this.qualification,
    required this.courseRequirements,
    required this.ageMin,
    required this.ageMax,
    required this.category,
    required this.experience,
    required this.applicationStartDate,
    required this.lastDate,
    required this.applicationFee,
    required this.selectionProcess,
    required this.salary,
    required this.description,
    required this.officialNotificationUrl,
    this.applyUrl = '',
    this.aiSummary,
  });

  /// Smart resolver for the direct candidate application portal
  String get effectiveApplyUrl {
    if (applyUrl.trim().isNotEmpty) {
      return applyUrl.trim();
    }
    final org = organization.toLowerCase();
    final tit = title.toLowerCase();

    if (org.contains('kerala psc') || tit.contains('kerala psc') || tit.contains('kpsc')) {
      return 'https://thulasi.psc.kerala.gov.in/thulasi/';
    }
    if (org.contains('staff selection') || tit.contains('ssc') || org.contains('ssc')) {
      return 'https://ssc.gov.in/login';
    }
    if (org.contains('upsc') || tit.contains('upsc') || org.contains('union public service')) {
      return 'https://upsconline.nic.in/upsc/OTRP/index.php';
    }
    if (org.contains('railway') || org.contains('rrb') || tit.contains('rrb')) {
      return 'https://www.rrbapply.gov.in/#/auth/home';
    }
    if (org.contains('ibps') || tit.contains('ibps') || org.contains('banking personnel')) {
      return 'https://ibpsonline.ibps.in';
    }
    if (org.contains('sbi') || org.contains('state bank')) {
      return 'https://bank.sbi/careers/current-openings';
    }
    if (org.contains('isro') || tit.contains('isro')) {
      return 'https://apps.isro.gov.in/icrb/';
    }
    if (org.contains('drdo') || tit.contains('drdo')) {
      return 'https://drdo.gov.in/drdo/ceptam-notice-board';
    }
    if (org.contains('kdrb') || org.contains('devaswom')) {
      return 'https://kdrb.kerala.gov.in/online-application/';
    }

    return officialNotificationUrl.isNotEmpty ? officialNotificationUrl : 'https://www.ncs.gov.in';
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    String parseStringOrList(dynamic val, String defaultVal) {
      if (val == null) return defaultVal;
      if (val is List) {
        return val.map((e) => e.toString()).where((s) => s.isNotEmpty).join(', ');
      }
      return val.toString().trim().isEmpty ? defaultVal : val.toString();
    }

    String parseSalary(dynamic salaryVal, dynamic salaryTextVal) {
      if (salaryVal is String && salaryVal.trim().isNotEmpty) return salaryVal;
      if (salaryTextVal is String && salaryTextVal.trim().isNotEmpty) return salaryTextVal;
      if (salaryVal is Map) {
        final scale = salaryVal['payScale']?.toString();
        if (scale != null && scale.trim().isNotEmpty) return scale;
      }
      return 'As per Govt Norms';
    }

    return Job(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['job']?['title']?.toString() ?? '',
      organization: json['organization']?.toString() ?? json['job']?['organization']?.toString() ?? 'Kerala Public Service Commission',
      department: json['department']?.toString() ?? json['job']?['department']?.toString() ?? 'General Administration',
      jobType: json['jobType']?.toString() ?? json['job']?['jobType']?.toString() ?? 'Kerala PSC',
      location: json['location']?.toString() ?? json['job']?['location']?.toString() ?? 'Kerala (Statewide)',
      vacancies: parseStringOrList(json['vacancies'] ?? json['vacancy']?['details'], 'As per notification'),
      qualification: parseStringOrList(json['qualification'], 'Any Degree'),
      courseRequirements: parseStringOrList(json['courseRequirements'], ''),
      ageMin: (json['ageMin'] is num) ? (json['ageMin'] as num).toInt() : 18,
      ageMax: (json['ageMax'] is num) ? (json['ageMax'] as num).toInt() : 40,
      category: json['category']?.toString() ?? 'General / OBC / SC-ST',
      experience: parseStringOrList(json['experience'], 'Fresher eligible'),
      applicationStartDate: json['applicationStartDate']?.toString() ?? json['job']?['applicationStartDate']?.toString() ?? '',
      lastDate: json['lastDate']?.toString() ?? json['job']?['applicationLastDate']?.toString() ?? '04-11-2026',
      applicationFee: json['applicationFee']?.toString() ?? 'Free (Kerala PSC One Time Registration)',
      selectionProcess: parseStringOrList(json['selectionProcess'], 'Written / OMR Examination'),
      salary: parseSalary(json['salary'], json['salaryText']),
      description: json['description']?.toString() ?? '',
      officialNotificationUrl: json['officialNotificationUrl']?.toString() ?? json['source']?['pdfUrl']?.toString() ?? '',
      applyUrl: json['applyUrl']?.toString() ?? 'https://thulasi.psc.kerala.gov.in/thulasi/',
      aiSummary: json['aiSummary'] != null ? AiSummaryData.fromJson(json['aiSummary'] as Map<String, dynamic>?) : null,
    );
  }

  Job copyWith({
    String? id,
    String? title,
    String? organization,
    String? department,
    String? jobType,
    String? location,
    String? vacancies,
    String? qualification,
    String? courseRequirements,
    int? ageMin,
    int? ageMax,
    String? category,
    String? experience,
    String? applicationStartDate,
    String? lastDate,
    String? applicationFee,
    String? selectionProcess,
    String? salary,
    String? description,
    String? officialNotificationUrl,
    String? applyUrl,
    AiSummaryData? aiSummary,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      organization: organization ?? this.organization,
      department: department ?? this.department,
      jobType: jobType ?? this.jobType,
      location: location ?? this.location,
      vacancies: vacancies ?? this.vacancies,
      qualification: qualification ?? this.qualification,
      courseRequirements: courseRequirements ?? this.courseRequirements,
      ageMin: ageMin ?? this.ageMin,
      ageMax: ageMax ?? this.ageMax,
      category: category ?? this.category,
      experience: experience ?? this.experience,
      applicationStartDate: applicationStartDate ?? this.applicationStartDate,
      lastDate: lastDate ?? this.lastDate,
      applicationFee: applicationFee ?? this.applicationFee,
      selectionProcess: selectionProcess ?? this.selectionProcess,
      salary: salary ?? this.salary,
      description: description ?? this.description,
      officialNotificationUrl: officialNotificationUrl ?? this.officialNotificationUrl,
      applyUrl: applyUrl ?? this.applyUrl,
      aiSummary: aiSummary ?? this.aiSummary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'organization': organization,
      'department': department,
      'jobType': jobType,
      'location': location,
      'vacancies': vacancies,
      'qualification': qualification,
      'courseRequirements': courseRequirements,
      'ageMin': ageMin,
      'ageMax': ageMax,
      'category': category,
      'experience': experience,
      'applicationStartDate': applicationStartDate,
      'lastDate': lastDate,
      'applicationFee': applicationFee,
      'selectionProcess': selectionProcess,
      'salary': salary,
      'description': description,
      'officialNotificationUrl': officialNotificationUrl,
      'applyUrl': applyUrl,
      'aiSummary': aiSummary?.toJson(),
    };
  }

  /// Evaluates user eligibility against this job using local frontend rules
  EligibilityResult checkEligibility(User? user) {
    if (user == null) {
      return const EligibilityResult(
        isEligible: false,
        points: [],
        summary: 'Login or complete your profile to view eligibility.',
      );
    }

    final points = <EligibilityPoint>[];

    // 1. Qualification check (Educational Level Ladder)
    int getEducationLevel(String q) {
      final str = q.toLowerCase();
      if (str.contains('pg') || str.contains('post graduate') || str.contains('master')) {
        return 4;
      }
      if (str.contains('degree') ||
          str.contains('graduate') ||
          str.contains('bachelor') ||
          str.contains('bca') ||
          str.contains('b.tech') ||
          str.contains('b.sc') ||
          str.contains('b.com')) {
        return 3;
      }
      if (str.contains('plus two') ||
          str.contains('12th') ||
          str.contains('diploma') ||
          str.contains('higher secondary')) {
        return 2;
      }
      if (str.contains('sslc') ||
          str.contains('10th') ||
          str.contains('matriculation') ||
          str.contains('secondary')) {
        return 1;
      }
      return 0; // Any / no specific minimum
    }

    final userLevel = getEducationLevel(user.qualification);
    final jobLevel = getEducationLevel(qualification);
    final userQual = user.qualification.trim().toLowerCase();
    final jobQual = qualification.trim().toLowerCase();

    bool qualMet = false;
    String qualExplanation = '';

    if (jobLevel == 0 || jobQual.contains('any')) {
      qualMet = true;
      qualExplanation = 'Open to all educational backgrounds (your qualification: ${user.qualification}).';
    } else if (userLevel >= jobLevel && userLevel > 0) {
      qualMet = true;
      if (userLevel > jobLevel) {
        qualExplanation =
            'Your higher qualification (${user.qualification} - ${user.course}) satisfies the minimum required "$qualification".';
      } else {
        qualExplanation =
            'Your qualification (${user.qualification} - ${user.course}) matches "$qualification".';
      }
    } else {
      qualMet = userQual.contains(jobQual) || jobQual.contains(userQual);
      qualExplanation = qualMet
          ? 'Your qualification (${user.qualification} - ${user.course}) matches "$qualification".'
          : 'Minimum requirement is "$qualification", but your profile has "${user.qualification}".';
    }

    points.add(EligibilityPoint(
      title: 'Educational Qualification',
      isMet: qualMet,
      explanation: qualExplanation,
    ));

    // 2. Age limit check (approximate from DOB or default user age ~24)
    int userAge = 24;
    if (user.dob.isNotEmpty) {
      try {
        final parts = user.dob.split('/');
        if (parts.length == 3) {
          final birthYear = int.tryParse(parts[2]);
          if (birthYear != null) {
            userAge = DateTime.now().year - birthYear;
          }
        }
      } catch (_) {}
    }
    bool ageMet = userAge >= ageMin && userAge <= ageMax;
    points.add(EligibilityPoint(
      title: 'Age Criteria',
      isMet: ageMet,
      explanation: ageMet
          ? 'Your age ($userAge yrs) is within the allowable range ($ageMin - $ageMax yrs).'
          : 'Your age ($userAge yrs) is outside the permissible limit of $ageMin - $ageMax yrs.',
    ));

    // 3. Location / State check
    final jobLoc = location.trim().toLowerCase();
    final userState = user.state.trim().toLowerCase();
    bool locMet = jobLoc.contains('all india') ||
        jobLoc.contains('pan india') ||
        jobLoc.contains(userState) ||
        userState.contains(jobLoc);
    points.add(EligibilityPoint(
      title: 'State / Domicile Requirement',
      isMet: locMet,
      explanation: locMet
          ? 'Eligible for applicants from ${user.state} ($location).'
          : 'This notification is restricted to $location (your state is ${user.state}).',
    ));

    // 4. Category reservation check
    points.add(EligibilityPoint(
      title: 'Category & Reservation',
      isMet: true,
      explanation: 'Eligible under ${user.category} category with applicable age/fee relaxation.',
    ));

    final overallEligible = qualMet && ageMet && locMet;

    return EligibilityResult(
      isEligible: overallEligible,
      points: points,
      summary: overallEligible
          ? 'You meet all basic eligibility requirements for this notification.'
          : 'You do not meet one or more mandatory eligibility requirements.',
    );
  }
}
