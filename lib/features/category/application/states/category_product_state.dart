import '../../domain/entities/category_product.dart';

enum CategoryProductStatus { initial, loading, data, empty, error }

class CategoryProductState {
  const CategoryProductState({
    required this.status,
    required this.products,
    required this.isRefreshing,
    this.lastSyncedAt,
    this.lastModified,
    this.refreshStartedAt,
    this.refreshEndedAt,
    this.errorMessage,
    this.totalCount,
    this.next,
    this.previous,
  });

  factory CategoryProductState.initial() => const CategoryProductState(
    status: CategoryProductStatus.initial,
    products: <CategoryProduct>[],
    isRefreshing: false,
    refreshStartedAt: null,
    refreshEndedAt: null,
  );

  final CategoryProductStatus status;
  final List<CategoryProduct> products;
  final bool isRefreshing;
  final DateTime? lastSyncedAt;
  final String? lastModified;
  final DateTime? refreshStartedAt;
  final DateTime? refreshEndedAt;
  final String? errorMessage;
  final int? totalCount;
  final String? next;
  final String? previous;

  bool get hasData => products.isNotEmpty;
  bool get isLoading => status == CategoryProductStatus.loading;
  bool get isError => status == CategoryProductStatus.error;
  bool get isEmpty => status == CategoryProductStatus.empty;
  bool get hasMore => next != null;

  CategoryProductState copyWith({
    CategoryProductStatus? status,
    List<CategoryProduct>? products,
    bool? isRefreshing,
    DateTime? lastSyncedAt,
    String? lastModified,
    DateTime? refreshStartedAt,
    DateTime? refreshEndedAt,
    String? errorMessage,
    int? totalCount,
    String? next,
    String? previous,
    bool clearError = false,
    bool resetRefreshStartedAt = false,
    bool resetRefreshEndedAt = false,
  }) {
    return CategoryProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastModified: lastModified ?? this.lastModified,
      refreshStartedAt: resetRefreshStartedAt
          ? null
          : (refreshStartedAt ?? this.refreshStartedAt),
      refreshEndedAt: resetRefreshEndedAt
          ? null
          : (refreshEndedAt ?? this.refreshEndedAt),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      totalCount: totalCount ?? this.totalCount,
      next: next ?? this.next,
      previous: previous ?? this.previous,
    );
  }
}
