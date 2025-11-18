import '../../domain/entities/profile.dart';

class ProfileDto {
  const ProfileDto({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    this.email,
    this.location,
    this.profileImageUrl,
  });

  final String id;
  final String fullName;
  final String mobileNumber;
  final String? email;
  final String? location;
  final String? profileImageUrl;

  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['user_id'] ?? json['uuid'];
    if (rawId == null) {
      throw const FormatException('Profile payload missing `id`.');
    }

    final rawName =
        json['full_name'] ?? json['name'] ?? json['first_name'] ?? json['username'];
    if (rawName == null) {
      throw const FormatException('Profile payload missing `name`.');
    }

    final rawMobile =
        json['mobile_number'] ?? json['phone'] ?? json['mobile'] ?? json['phone_number'];
    if (rawMobile == null) {
      throw const FormatException('Profile payload missing `mobile_number`.');
    }

    return ProfileDto(
      id: '$rawId',
      fullName: '$rawName',
      mobileNumber: '$rawMobile',
      email: json['email']?.toString(),
      location: json['location']?.toString() ?? json['address']?.toString(),
      profileImageUrl: json['profile_image']?.toString() ??
          json['avatar']?.toString() ??
          json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'full_name': fullName,
        'mobile_number': mobileNumber,
        if (email != null) 'email': email,
        if (location != null) 'location': location,
        if (profileImageUrl != null) 'profile_image': profileImageUrl,
      };

  Profile toDomain() => Profile(
        id: id,
        fullName: fullName,
        mobileNumber: mobileNumber,
        email: email,
        location: location,
        profileImageUrl: profileImageUrl,
      );
}
