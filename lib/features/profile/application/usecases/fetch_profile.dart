import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

class FetchProfile {
  const FetchProfile({required ProfileRepository repository})
    : _repository = repository;

  final ProfileRepository _repository;

  Future<Profile> call() async {
    return _repository.fetchProfile();
  }
}
