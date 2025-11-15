import '../../domain/entities/category.dart';

enum CategoryStatus { initial, loading, data, empty, error }

class CategoryState {
  const CategoryState({
    required this.status,
    required this.categories,
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

  factory CategoryState.initial() => const CategoryState(
    status: CategoryStatus.initial,
    categories: <Category>[],
    isRefreshing: false,
    refreshStartedAt: null,
    refreshEndedAt: null,
  );

  final CategoryStatus status;
  final List<Category> categories;
  final bool isRefreshing;
  final DateTime? lastSyncedAt;
  final String? lastModified;
  final DateTime? refreshStartedAt;
  final DateTime? refreshEndedAt;
  final String? errorMessage;
  final int? totalCount;
  final String? next;
  final String? previous;

  bool get hasData => categories.isNotEmpty;
  bool get isLoading => status == CategoryStatus.loading;
  bool get isError => status == CategoryStatus.error;
  bool get isEmpty => status == CategoryStatus.empty;
  bool get hasMore => next != null;

  CategoryState copyWith({
    CategoryStatus? status,
    List<Category>? categories,
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
    return CategoryState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
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
