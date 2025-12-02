import '../../domain/entities/profile.dart';

class ProfileDto {
  const ProfileDto({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.email,
    this.username,
    this.role,
    this.profileImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? email;
  final String? username;
  final String? role;
  final String? profileImageUrl;
  final String? createdAt;
  final String? updatedAt;

  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['user_id'] ?? json['uuid'];
    if (rawId == null) {
      throw const FormatException('Profile payload missing `id`.');
    }

    final rawFirstName = json['first_name'];
    if (rawFirstName == null || rawFirstName.toString().isEmpty) {
      throw const FormatException('Profile payload missing `first_name`.');
    }

    final rawLastName = json['last_name'];
    if (rawLastName == null || rawLastName.toString().isEmpty) {
      throw const FormatException('Profile payload missing `last_name`.');
    }

    final rawPhone = json['phone_number'];
    if (rawPhone == null || rawPhone.toString().isEmpty) {
      throw const FormatException('Profile payload missing `phone_number`.');
    }

    return ProfileDto(
      id: '$rawId',
      firstName: '$rawFirstName',
      lastName: '$rawLastName',
      phoneNumber: '$rawPhone',
      email: json['email']?.toString(),
      username: json['username']?.toString(),
      role: json['role']?.toString(),
      profileImageUrl:
          json['profile_image']?.toString() ??
          json['avatar']?.toString() ??
          json['image']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'phone_number': phoneNumber,
    if (email != null) 'email': email,
    if (username != null) 'username': username,
    if (role != null) 'role': role,
    if (profileImageUrl != null) 'profile_image': profileImageUrl,
  };

  Profile toDomain() => Profile(
    id: id,
    fullName: '$firstName $lastName',
    mobileNumber: phoneNumber,
    email: email,
    location: null, // Location is UI-only, not from API
    profileImageUrl: profileImageUrl,
  );

  /// Helper method to get fullName for API requests
  static Map<String, String> splitFullName(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) {
      return {'first_name': parts[0], 'last_name': ''};
    }
    return {'first_name': parts.first, 'last_name': parts.sublist(1).join(' ')};
  }
}
