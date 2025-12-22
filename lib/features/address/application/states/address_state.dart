import '../../domain/entities/address.dart';

enum AddressStatus { initial, loading, data, error }

class AddressState {
  const AddressState({
    required this.status,
    this.addresses = const [],
    this.errorMessage,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.isStale = false,
    this.localSelectedAddressId,
  });

  factory AddressState.initial() => const AddressState(
    status: AddressStatus.initial,
    addresses: [],
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
    isStale: false,
    localSelectedAddressId: null,
  );

  final AddressStatus status;
  final List<Address> addresses;
  final String? errorMessage;
  final bool isCreating;
  final bool isUpdating;
  final bool isDeleting;
  final bool isStale;

  /// Locally tracked selected address ID to work around buggy backend API
  /// The GET endpoint returns wrong selected address, so we track it locally
  final String? localSelectedAddressId;

  bool get hasData => addresses.isNotEmpty;
  bool get isLoading => status == AddressStatus.loading;
  bool get isError => status == AddressStatus.error;

  AddressState copyWith({
    AddressStatus? status,
    List<Address>? addresses,
    String? errorMessage,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    bool? isStale,
    String? localSelectedAddressId,
    bool clearError = false,
    bool clearLocalSelectedAddressId = false,
  }) {
    return AddressState(
      status: status ?? this.status,
      addresses: addresses ?? this.addresses,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      isStale: isStale ?? this.isStale,
      localSelectedAddressId: clearLocalSelectedAddressId
          ? null
          : (localSelectedAddressId ?? this.localSelectedAddressId),
    );
  }
}
