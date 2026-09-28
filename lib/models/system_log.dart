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
}
