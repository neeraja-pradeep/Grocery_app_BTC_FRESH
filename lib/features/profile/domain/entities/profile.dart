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
}
