enum ScrapedJobReviewStatus { pending, approved, rejected, expired }

class ScrapedJob {
  final String id;
  final String title;
  final String organization;
  final String source;
  final String location;
  final String lastDate;
  final String vacancies;
  final String qualification;
  final String salary;
  final String scrapedDate;
  final ScrapedJobReviewStatus reviewStatus;
  final String? rejectionReason;
  final String officialUrl;

  const ScrapedJob({
    required this.id,
    required this.title,
    required this.organization,
    required this.source,
    required this.location,
    required this.lastDate,
    required this.vacancies,
    required this.qualification,
    required this.salary,
    required this.scrapedDate,
    this.reviewStatus = ScrapedJobReviewStatus.pending,
    this.rejectionReason,
    required this.officialUrl,
  });

  ScrapedJob copyWith({
    String? id,
    String? title,
    String? organization,
    String? source,
    String? location,
    String? lastDate,
    String? vacancies,
    String? qualification,
    String? salary,
    String? scrapedDate,
    ScrapedJobReviewStatus? reviewStatus,
    String? rejectionReason,
    String? officialUrl,
  }) {
    return ScrapedJob(
      id: id ?? this.id,
      title: title ?? this.title,
      organization: organization ?? this.organization,
      source: source ?? this.source,
      location: location ?? this.location,
      lastDate: lastDate ?? this.lastDate,
      vacancies: vacancies ?? this.vacancies,
      qualification: qualification ?? this.qualification,
      salary: salary ?? this.salary,
      scrapedDate: scrapedDate ?? this.scrapedDate,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      officialUrl: officialUrl ?? this.officialUrl,
    );
  }
}
