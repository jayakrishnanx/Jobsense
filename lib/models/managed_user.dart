enum UserAccountStatus { active, blocked }

class ManagedUser {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String registrationDate;
  final UserAccountStatus status;
  final int profileCompletion;
  final int eligibleJobsCount;
  final String qualification;
  final String category;
  final String state;
  final String? blockReason;

  const ManagedUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.registrationDate,
    this.status = UserAccountStatus.active,
    required this.profileCompletion,
    required this.eligibleJobsCount,
    required this.qualification,
    required this.category,
    required this.state,
    this.blockReason,
  });

  ManagedUser copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? registrationDate,
    UserAccountStatus? status,
    int? profileCompletion,
    int? eligibleJobsCount,
    String? qualification,
    String? category,
    String? state,
    String? blockReason,
  }) {
    return ManagedUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      registrationDate: registrationDate ?? this.registrationDate,
      status: status ?? this.status,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      eligibleJobsCount: eligibleJobsCount ?? this.eligibleJobsCount,
      qualification: qualification ?? this.qualification,
      category: category ?? this.category,
      state: state ?? this.state,
      blockReason: blockReason ?? this.blockReason,
    );
  }

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    final isActive = json['isActive'] != false;
    return ManagedUser(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      registrationDate: json['createdAt'] != null
          ? json['createdAt'].toString().split('T')[0]
          : (json['registrationDate'] ?? 'Recently'),
      status: isActive ? UserAccountStatus.active : UserAccountStatus.blocked,
      profileCompletion: json['profileCompletion'] ?? 85,
      eligibleJobsCount: json['eligibleJobsCount'] ?? 5,
      qualification: json['qualification'] ?? 'Degree',
      category: json['category'] ?? 'General',
      state: json['state'] ?? 'Kerala',
      blockReason: json['blockReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'registrationDate': registrationDate,
      'status': status.name,
      'profileCompletion': profileCompletion,
      'eligibleJobsCount': eligibleJobsCount,
      'qualification': qualification,
      'category': category,
      'state': state,
      'blockReason': blockReason,
    };
  }
}

