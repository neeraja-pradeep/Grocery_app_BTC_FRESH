// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$categoryDetailsHash() => r'df5832ba38b71da12220e3a0c4b40f77d4774a37';

/// See also [CategoryDetails].
@ProviderFor(CategoryDetails)
final categoryDetailsProvider =
    AutoDisposeNotifierProvider<
      CategoryDetails,
      AsyncValue<PaginatedResult<Category>>
    >.internal(
      CategoryDetails.new,
      name: r'categoryDetailsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$categoryDetailsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CategoryDetails =
    AutoDisposeNotifier<AsyncValue<PaginatedResult<Category>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
