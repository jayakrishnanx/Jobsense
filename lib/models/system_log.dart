enum LogLevel { info, success, warning, error }

class SystemLog {
  final String id;
  final String timestamp;
  final String eventType;
  final String description;
  final LogLevel level;
  final String? source;

  const SystemLog({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.description,
    this.level = LogLevel.info,
    this.source,
  });

  SystemLog copyWith({
    String? id,
    String? timestamp,
    String? eventType,
    String? description,
    LogLevel? level,
    String? source,
  }) {
    return SystemLog(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      eventType: eventType ?? this.eventType,
      description: description ?? this.description,
      level: level ?? this.level,
      source: source ?? this.source,
    );
  }

  factory SystemLog.fromJson(Map<String, dynamic> json) {
    LogLevel level = LogLevel.info;
    final lvlStr = (json['level'] ?? '').toString().toUpperCase();
    if (lvlStr == 'SUCCESS') {
      level = LogLevel.success;
    } else if (lvlStr == 'WARN' || lvlStr == 'WARNING') {
      level = LogLevel.warning;
    } else if (lvlStr == 'ERROR') {
      level = LogLevel.error;
    }

    return SystemLog(
      id: json['id'] ?? json['_id'] ?? '',
      timestamp: json['timestamp'] != null
          ? json['timestamp'].toString().replaceFirst('T', ' ').split('.')[0]
          : 'Just now',
      eventType: json['category'] ?? json['eventType'] ?? 'SYSTEM',
      description: json['message'] ?? json['description'] ?? '',
      level: level,
      source: json['details'] ?? json['source'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp,
      'category': eventType,
      'message': description,
      'level': level.name.toUpperCase(),
      'details': source,
    };
  }
}

