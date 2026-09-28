enum ScraperStatus { active, inactive, failed }

class Scraper {
  final String id;
  final String name;
  final String website;
  final ScraperStatus status;
  final String lastRun;
  final int jobsCollected;
  final String? lastError;
  final String frequency;
  final String department;

  const Scraper({
    required this.id,
    required this.name,
    required this.website,
    required this.status,
    required this.lastRun,
    required this.jobsCollected,
    this.lastError,
    this.frequency = 'Every 6 Hours',
    this.department = 'Central / State Portal',
  });

  Scraper copyWith({
    String? id,
    String? name,
    String? website,
    ScraperStatus? status,
    String? lastRun,
    int? jobsCollected,
    String? lastError,
    String? frequency,
    String? department,
  }) {
    return Scraper(
      id: id ?? this.id,
      name: name ?? this.name,
      website: website ?? this.website,
      status: status ?? this.status,
      lastRun: lastRun ?? this.lastRun,
      jobsCollected: jobsCollected ?? this.jobsCollected,
      lastError: lastError,
      frequency: frequency ?? this.frequency,
      department: department ?? this.department,
    );
  }
}
