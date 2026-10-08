class User {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String dob;
  final String gender;
  final String qualification;
  final String course;
  final String yearOfPassing;
  final String category;
  final String state;
  final String district;

  const User({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.dob,
    required this.gender,
    required this.qualification,
    required this.course,
    required this.yearOfPassing,
    required this.category,
    required this.state,
    required this.district,
  });

  User copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? dob,
    String? gender,
    String? qualification,
    String? course,
    String? yearOfPassing,
    String? category,
    String? state,
    String? district,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      qualification: qualification ?? this.qualification,
      course: course ?? this.course,
      yearOfPassing: yearOfPassing ?? this.yearOfPassing,
      category: category ?? this.category,
      state: state ?? this.state,
      district: district ?? this.district,
    );
  }

  /// Calculates profile completion percentage (0 to 100)
  int get completionPercentage {
    final fields = [
      name,
      phone,
      email,
      dob,
      gender,
      qualification,
      course,
      yearOfPassing,
      category,
      state,
      district,
    ];
    int filled = fields.where((f) => f.trim().isNotEmpty).length;
    return ((filled / fields.length) * 100).round();
  }

  /// Returns list of unfilled profile fields
  List<String> get missingFields {
    final missing = <String>[];
    if (email.trim().isEmpty) missing.add('Email');
    if (dob.trim().isEmpty) missing.add('Date of Birth');
    if (gender.trim().isEmpty) missing.add('Gender');
    if (qualification.trim().isEmpty) missing.add('Qualification');
    if (course.trim().isEmpty) missing.add('Course');
    if (yearOfPassing.trim().isEmpty) missing.add('Year of Passing');
    if (category.trim().isEmpty) missing.add('Category');
    if (state.trim().isEmpty) missing.add('State');
    if (district.trim().isEmpty) missing.add('District');
    return missing;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',
      qualification: json['qualification'] ?? '',
      course: json['course'] ?? '',
      yearOfPassing: json['yearOfPassing'] ?? '',
      category: json['category'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'dob': dob,
      'gender': gender,
      'qualification': qualification,
      'course': course,
      'yearOfPassing': yearOfPassing,
      'category': category,
      'state': state,
      'district': district,
    };
  }
}

