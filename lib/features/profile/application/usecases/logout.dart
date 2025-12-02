import '../../domain/repositories/profile_repository.dart';

class Logout {
  const Logout({required ProfileRepository repository})
    : _repository = repository;

  final ProfileRepository _repository;

  Future<void> call() async {
    return _repository.logout();
  }
}
