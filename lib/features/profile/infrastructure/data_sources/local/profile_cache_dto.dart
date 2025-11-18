import '../../models/profile_dto.dart';

class ProfileCacheDto {
  const ProfileCacheDto({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    this.email,
    this.location,
    this.profileImageUrl,
    required this.cachedAt,
  });

  final String id;
  final String fullName;
  final String mobileNumber;
  final String? email;
  final String? location;
  final String? profileImageUrl;
  final DateTime cachedAt;

  factory ProfileCacheDto.fromJson(Map<String, dynamic> json) {
    return ProfileCacheDto(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      mobileNumber: json['mobileNumber'] as String,
      email: json['email'] as String?,
      location: json['location'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'fullName': fullName,
        'mobileNumber': mobileNumber,
        if (email != null) 'email': email,
        if (location != null) 'location': location,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        'cachedAt': cachedAt.toIso8601String(),
      };

  ProfileDto toDto() => ProfileDto(
        id: id,
        fullName: fullName,
        mobileNumber: mobileNumber,
        email: email,
        location: location,
        profileImageUrl: profileImageUrl,
      );

  factory ProfileCacheDto.fromDto(ProfileDto dto) {
    return ProfileCacheDto(
      id: dto.id,
      fullName: dto.fullName,
      mobileNumber: dto.mobileNumber,
      email: dto.email,
      location: dto.location,
      profileImageUrl: dto.profileImageUrl,
      cachedAt: DateTime.now(),
    );
  }
}
