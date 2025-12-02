import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

class UpdateProfile {
  const UpdateProfile({required ProfileRepository repository})
    : _repository = repository;

  final ProfileRepository _repository;

  Future<Profile> call({
    required String fullName,
    required String phoneNumber,
  }) async {
    return _repository.updateProfile(
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
  }
}
