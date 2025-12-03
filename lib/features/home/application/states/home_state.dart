// lib/features/home/application/states/home_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/banner.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_discount_group.dart';
import '../../domain/entities/product_variant.dart';
import '../../domain/entities/user_address.dart';

part 'home_state.freezed.dart';

@freezed
sealed class HomeState with _$HomeState {
  // Initial state before any action
  const factory HomeState.initial() = HomeInitial;

  // First-time full screen loading
  const factory HomeState.loading() = HomeLoading;

  // Successfully loaded content (supports incremental updates)
  const factory HomeState.loaded({
    required List<Category> categories,
    UserAddress? selectedAddress,
    required List<ProductVariant> bestDeals,
    required List<CategoryDiscountGroup> discountGroups,
    Banner? activeAd, // Using 'Banner' entity for Advertisement
    // Separate loading flags for sections (for incremental UI updates)
    @Default(false) bool categoriesLoading,
    @Default(false) bool bestDealsLoading,
    @Default(false) bool discountsLoading,
  }) = HomeLoaded;

  // Pull-to-refresh state (keeps data visible)
  const factory HomeState.refreshing({
    required List<Category> categories,
    UserAddress? selectedAddress,
    required List<ProductVariant> bestDeals,
    required List<CategoryDiscountGroup> discountGroups,
    Banner? activeAd,
  }) = HomeRefreshing;

  // Error state (optional: keep previous state to show stale data + snackbar)
  const factory HomeState.error({
    required Failure failure,
    HomeState? previousState,
  }) = HomeError;
}
