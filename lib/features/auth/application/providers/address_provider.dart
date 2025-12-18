import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/address_enum.dart';
import '../../domain/repositories/auth_repository.dart';
import '../states/address_states.dart';
import 'auth_repository_provider.dart';

part 'address_provider.g.dart';

@riverpod
class AddressEntry extends _$AddressEntry {
  late final AuthRepository _repository;

  @override
  AddressState build() {
    _repository = ref.read(authRepositoryProvider);
    return AddressInitial();
  }

  Future<void> saveAddress({
    required String firstName,
    required String lastName,
    required String streetAddress,
    required AddressType addressType,
    String? streetAddress2,
    String? latitude,
    String? longitude,
    String? city,
    String? state,
    String? postalCode,
  }) async {
    this.state = AddressSaving();

    final result = await _repository.addAddress(
      firstName: firstName,
      lastName: lastName,
      streetAddress: streetAddress,
      addressType: addressType.name, // backend expects string
      streetAddress2: streetAddress2,
      latitude: latitude,
      longitude: longitude,
      city: city,
      state: state,
      postalCode: postalCode,
    );

    result.fold(
      (failure) {
        this.state = AddressError(failure);
      },
      (address) {
        this.state = AddressSaved(address);
      },
    );
  }

  void skipAddress() {
    state = AddressSkipped();
  }
}
