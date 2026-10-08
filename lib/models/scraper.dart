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

  factory Scraper.fromJson(Map<String, dynamic> json) {
    ScraperStatus status = ScraperStatus.active;
    final statusStr = (json['status'] ?? '').toString().toLowerCase();
    if (statusStr == 'failed') {
      status = ScraperStatus.failed;
    } else if (statusStr == 'inactive' || statusStr == 'paused' || statusStr == 'idle') {
      status = ScraperStatus.inactive;
    }

    return Scraper(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      website: json['targetUrl'] ?? json['website'] ?? '',
      status: status,
      lastRun: json['lastRunTime'] != null
          ? json['lastRunTime'].toString().split('T')[0]
          : (json['lastRun'] ?? 'Recently'),
      jobsCollected: json['jobsFound'] ?? json['jobsCollected'] ?? 0,
      lastError: json['errorMessage'] ?? json['lastError'],
      frequency: json['schedule'] ?? json['frequency'] ?? 'Every 4 Hours',
      department: json['category'] ?? json['department'] ?? 'Government Portal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetUrl': website,
      'status': status.name,
      'lastRun': lastRun,
      'jobsFound': jobsCollected,
      'errorMessage': lastError,
      'schedule': frequency,
      'category': department,
    };
  }
}

