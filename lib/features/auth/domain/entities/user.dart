// lib/features/auth/domain/entities/user.dart

/// User entity
class User {
  final String id;
  final String email;
  final String name;

  const User({required this.id, required this.email, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'name': name};
  }
}
