import 'package:equatable/equatable.dart';
import '../../domain/entities/address.dart';

/// Status of address list data
enum AddressStatus { initial, loading, data, error, empty }

/// State for address list feature
/// Manages address list data, loading states, and refresh indicators
class AddressState extends Equatable {
  const AddressState({
    this.status = AddressStatus.initial,
    this.addressList,
    this.errorMessage,
    this.lastSyncedAt,
    this.isRefreshing = false,
    this.refreshStartedAt,
    this.refreshEndedAt,
    this.localSelectedAddress,
  });

  final AddressStatus status;
  final AddressListResponse? addressList;
  final String? errorMessage;
  final DateTime? lastSyncedAt;
  final bool isRefreshing;
  final DateTime? refreshStartedAt;
  final DateTime? refreshEndedAt;

  /// Local UI-only selected address (overrides server's selected address)
  final Address? localSelectedAddress;

  /// Convenience getters
  bool get isLoading => status == AddressStatus.loading;
  bool get hasData => status == AddressStatus.data && addressList != null;
  bool get hasError => status == AddressStatus.error;
  bool get isEmpty => status == AddressStatus.empty;

  /// Get list of addresses
  List<Address> get addresses => addressList?.results ?? [];

  /// Get selected address (prioritizes local selection over server selection)
  Address? get selectedAddress =>
      localSelectedAddress ?? addressList?.selectedAddress;

  @override
  List<Object?> get props => [
    status,
    addressList,
    errorMessage,
    lastSyncedAt,
    isRefreshing,
    refreshStartedAt,
    refreshEndedAt,
    localSelectedAddress,
  ];

  AddressState copyWith({
    AddressStatus? status,
    AddressListResponse? addressList,
    String? errorMessage,
    DateTime? lastSyncedAt,
    bool? isRefreshing,
    DateTime? refreshStartedAt,
    DateTime? refreshEndedAt,
    Address? localSelectedAddress,
    bool resetRefreshStartedAt = false,
    bool resetRefreshEndedAt = false,
    bool resetLocalSelectedAddress = false,
  }) {
    return AddressState(
      status: status ?? this.status,
      addressList: addressList ?? this.addressList,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshStartedAt: resetRefreshStartedAt
          ? null
          : (refreshStartedAt ?? this.refreshStartedAt),
      refreshEndedAt: resetRefreshEndedAt
          ? null
          : (refreshEndedAt ?? this.refreshEndedAt),
      localSelectedAddress: resetLocalSelectedAddress
          ? null
          : (localSelectedAddress ?? this.localSelectedAddress),
    );
  }
}
