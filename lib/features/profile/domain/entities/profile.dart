class Profile {
  const Profile({
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

  Profile copyWith({
    String? id,
    String? fullName,
    String? mobileNumber,
    String? email,
    String? location,
    String? profileImageUrl,
  }) => Profile(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    mobileNumber: mobileNumber ?? this.mobileNumber,
    email: email ?? this.email,
    location: location ?? this.location,
    profileImageUrl: profileImageUrl ?? this.profileImageUrl,
  );
}
