import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/storage/hive/boxes.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../infrastructure/data_sources/local/profile_local_ds.dart';
import '../../infrastructure/data_sources/remote/profile_api.dart';
import '../../infrastructure/repositories/profile_repository_impl.dart';
import '../states/profile_state.dart';

final profileLocalDsProvider = Provider<ProfileLocalDs>((ref) {
  return ProfileLocalDs(box: Boxes.profileBox);
});

final profileApiProvider = Provider<ProfileApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileApi(client: apiClient);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final remoteDs = ref.watch(profileApiProvider);
  final localDs = ref.watch(profileLocalDsProvider);
  return ProfileRepositoryImpl(remoteDs: remoteDs, localDs: localDs);
});

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);

class ProfileController extends Notifier<ProfileState> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  ProfileState build() {
    return ProfileState.initial();
  }

  /// Fetches profile with cache-first strategy:
  /// 1. Shows cached data immediately (even if stale)
  /// 2. Always triggers background API refresh when showing cached data
  Future<void> fetchProfile() async {
    if (state.profile == null) {
      state = state.copyWith(status: ProfileStatus.loading, clearError: true);
    }

    try {
      final result = await _repository.fetchProfileWithCache();

      state = state.copyWith(
        status: ProfileStatus.data,
        profile: result.profile,
        isStale: result.isStale,
        clearError: true,
      );

      if (result.fromCache) {
        _refreshInBackground();
      }
    } catch (error) {
      final message = _mapError(error);

      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: message,
      );
    }
  }

  void _refreshInBackground() {
    _repository
        .refreshProfileFromApi()
        .then((freshProfile) {
          if (freshProfile != null) {
            state = state.copyWith(
              profile: freshProfile,
              isStale: false,
              clearError: true,
            );
          }
        })
        .catchError((Object e, StackTrace st) {
          debugPrint('[ProfileController] background refresh failed: $e\n$st');
        });
  }

  Future<void> refreshProfile() async {
    try {
      final freshProfile = await _repository.refreshProfileFromApi();

      if (freshProfile != null) {
        state = state.copyWith(
          status: ProfileStatus.data,
          profile: freshProfile,
          isStale: false,
          clearError: true,
        );
      } else {
        throw Exception('Failed to refresh profile');
      }
    } catch (error) {
      final message = _mapError(error);

      state = state.copyWith(errorMessage: message);

      rethrow;
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final updatedProfile = await _repository.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
      );

      state = state.copyWith(
        status: ProfileStatus.data,
        profile: updatedProfile,
        isUpdating: false,
        isStale: false,
        clearError: true,
      );
    } catch (error) {
      final message = _mapError(error);

      state = state.copyWith(isUpdating: false, errorMessage: message);

      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isDeletingAccount: true, clearError: true);

    try {
      await _repository.deleteAccount();

      state = ProfileState.initial();
    } catch (error) {
      final message = _mapError(error);

      state = state.copyWith(isDeletingAccount: false, errorMessage: message);

      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
      state = ProfileState.initial();
    } catch (error) {
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
