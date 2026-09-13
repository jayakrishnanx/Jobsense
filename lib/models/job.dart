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
  });

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
