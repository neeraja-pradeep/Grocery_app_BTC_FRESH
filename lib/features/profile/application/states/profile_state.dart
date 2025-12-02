import '../../domain/entities/profile.dart';

enum ProfileStatus { initial, loading, data, error }

class ProfileState {
  const ProfileState({
    required this.status,
    this.profile,
    this.errorMessage,
    this.isUpdating,
    this.isDeletingAccount,
    this.isStale = false,
  });

  factory ProfileState.initial() => const ProfileState(
    status: ProfileStatus.initial,
    profile: null,
    isUpdating: false,
    isDeletingAccount: false,
    isStale: false,
  );

  final ProfileStatus status;
  final Profile? profile;
  final String? errorMessage;
  final bool? isUpdating;
  final bool? isDeletingAccount;
  final bool isStale;

  bool get hasData => profile != null;
  bool get isLoading => status == ProfileStatus.loading;
  bool get isError => status == ProfileStatus.error;

  ProfileState copyWith({
    ProfileStatus? status,
    Profile? profile,
    String? errorMessage,
    bool? isUpdating,
    bool? isDeletingAccount,
    bool? isStale,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isUpdating: isUpdating ?? this.isUpdating,
      isDeletingAccount: isDeletingAccount ?? this.isDeletingAccount,
      isStale: isStale ?? this.isStale,
    );
  }
}
