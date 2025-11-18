import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/storage/hive/boxes.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../infrastructure/data_sources/local/profile_local_ds.dart';
import '../../infrastructure/data_sources/remote/profile_api.dart';
import '../../infrastructure/repositories/profile_repository_impl.dart';
import '../states/profile_state.dart';

final profileLocalDsProvider = Provider<ProfileLocalDs>((ref) {
  final box = Hive.box<dynamic>(AppHiveBoxes.profile);
  return ProfileLocalDs(box: box);
});

final profileApiProvider = Provider<ProfileApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileApi(client: apiClient);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final remoteDs = ref.watch(profileApiProvider);
  final localDs = ref.watch(profileLocalDsProvider);

  return ProfileRepositoryImpl(
    remoteDs: remoteDs,
    localDs: localDs,
  );
});

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);

class ProfileController extends Notifier<ProfileState> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  ProfileState build() {
    return ProfileState.initial();
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(
      status: ProfileStatus.loading,
      clearError: true,
    );

    try {
      final profile = await _repository.fetchProfile();

      state = state.copyWith(
        status: ProfileStatus.data,
        profile: profile,
        clearError: true,
      );
    } catch (error) {
      final message = _mapError(error);

      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: message,
      );
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    state = state.copyWith(
      isUpdating: true,
      clearError: true,
    );

    try {
      final updatedProfile = await _repository.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
      );

      state = state.copyWith(
        status: ProfileStatus.data,
        profile: updatedProfile,
        isUpdating: false,
        clearError: true,
      );
    } catch (error) {
      final message = _mapError(error);

      state = state.copyWith(
        isUpdating: false,
        errorMessage: message,
      );

      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(
      isDeletingAccount: true,
      clearError: true,
    );

    try {
      await _repository.deleteAccount();

      state = ProfileState.initial();
    } catch (error) {
      final message = _mapError(error);

      state = state.copyWith(
        isDeletingAccount: false,
        errorMessage: message,
      );

      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
      state = ProfileState.initial();
    } catch (error) {
      // Even if logout fails, reset the state
      state = ProfileState.initial();
      rethrow;
    }
  }

  String _mapError(Object error) {
    if (error is NetworkException) {
      return error.message;
    }
    if (error is FormatException) {
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }
}
