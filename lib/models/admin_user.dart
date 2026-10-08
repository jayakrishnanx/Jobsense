class AdminUser {
  final String id;
  final String username;
  final String name;
  final String email;
  final String role;
  final String lastLogin;

  const AdminUser({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.role,
    required this.lastLogin,
  });

  AdminUser copyWith({
    String? id,
    String? username,
    String? name,
    String? email,
    String? role,
    String? lastLogin,
  }) {
    return AdminUser(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? json['_id'] ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'Administrator',
      lastLogin: json['lastLogin'] != null
          ? json['lastLogin'].toString().split('T')[0]
          : (json['lastLogin'] ?? 'Recently'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'role': role,
      'lastLogin': lastLogin,
    };
  }
}

