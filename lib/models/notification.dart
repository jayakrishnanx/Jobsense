class JobNotification {
  final String id;
  final String jobId;
  final String title;
  final String organization;
  final String message;
  final String timestamp;
  final bool isRead;
  final bool isEligible;

  const JobNotification({
    required this.id,
    required this.jobId,
    required this.title,
    required this.organization,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.isEligible = true,
  });

  JobNotification copyWith({
    String? id,
    String? jobId,
    String? title,
    String? organization,
    String? message,
    String? timestamp,
    bool? isRead,
    bool? isEligible,
  }) {
    return JobNotification(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      title: title ?? this.title,
      organization: organization ?? this.organization,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isEligible: isEligible ?? this.isEligible,
    );
  }
}
