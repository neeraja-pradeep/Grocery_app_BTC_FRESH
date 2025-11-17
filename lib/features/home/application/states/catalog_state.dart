// application/states/catalog_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart' hide Category;
// NOTE: Removed 'as domain' alias
import 'package:new_app/features/home/domain/entities/category.dart';
import 'package:new_app/features/home/domain/entities/offer.dart';
import 'package:new_app/features/home/domain/entities/product.dart';
part 'catalog_state.freezed.dart';

/// Holds the actual catalog data displayed on the home screen.
@freezed
class CatalogState with _$CatalogState {
  const CatalogState._();
  const factory CatalogState({
    // Used unqualified names
    @Default(<Category>[]) List<Category> categories,
    @Default(<Product>[]) List<Product> bestDeals,
    @Default(<Offer>[]) List<Offer> megaOffers,

    @Default(false) bool isRefreshing,
    String? error,

    DateTime? lastUpdated,
  }) = _CatalogState;

  // Custom getter for the requested structure
  bool get hasData =>
      categories.isNotEmpty || bestDeals.isNotEmpty || megaOffers.isNotEmpty;
}
