import 'package:grocery_app/core/error/failure.dart';
import 'package:grocery_app/features/auth/domain/entities/address.dart';

sealed class AddressState {}

class AddressInitial extends AddressState {}

class AddressSaving extends AddressState {}

class AddressSaved extends AddressState {
  final AddressEntity address;
  AddressSaved(this.address);
}

class AddressSkipped extends AddressState {}

class AddressError extends AddressState {
  final Failure failure;
  AddressError(this.failure);
}
