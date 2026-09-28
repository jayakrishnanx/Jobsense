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
}
