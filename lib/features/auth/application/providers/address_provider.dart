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
  }) async {
    state = AddressSaving();

    final result = await _repository.addAddress(
      firstName: firstName,
      lastName: lastName,
      streetAddress: streetAddress,
      addressType: addressType.name, // backend expects string
    );

    result.fold(
      (failure) {
        state = AddressError(failure);
      },
      (address) {
        state = AddressSaved(address);
      },
    );
  }

  void skipAddress() {
    state = AddressSkipped();
  }
}
