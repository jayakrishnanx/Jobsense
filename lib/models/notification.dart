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

  factory JobNotification.fromJson(Map<String, dynamic> json) {
    return JobNotification(
      id: json['id'] ?? json['_id'] ?? '',
      jobId: json['jobId'] ?? '',
      title: json['title'] ?? '',
      organization: json['organization'] ?? 'Government Notification',
      message: json['body'] ?? json['message'] ?? '',
      timestamp: json['createdAt'] != null
          ? json['createdAt'].toString().replaceFirst('T', ' ').split('.')[0]
          : (json['timestamp'] ?? 'Today'),
      isRead: json['isRead'] == true,
      isEligible: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'title': title,
      'organization': organization,
      'body': message,
      'createdAt': timestamp,
      'isRead': isRead,
    };
  }
}

