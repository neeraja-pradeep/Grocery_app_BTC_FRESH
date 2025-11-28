import 'package:equatable/equatable.dart';
import '../../domain/entities/checkout_line.dart';

/// Status of checkout lines data
enum CheckoutLineStatus { initial, loading, data, error, empty }

/// State for checkout lines (cart items) feature
class CheckoutLineState extends Equatable {
  const CheckoutLineState({
    this.status = CheckoutLineStatus.initial,
    this.checkoutLines,
    this.errorMessage,
    this.lastSyncedAt,
    this.isRefreshing = false,
    this.refreshStartedAt,
    this.refreshEndedAt,
  });

  final CheckoutLineStatus status;
  final CheckoutLinesResponse? checkoutLines;
  final String? errorMessage;
  final DateTime? lastSyncedAt;
  final bool isRefreshing;
  final DateTime? refreshStartedAt;
  final DateTime? refreshEndedAt;

  /// Convenience getters
  bool get isLoading => status == CheckoutLineStatus.loading;
  bool get hasData =>
      status == CheckoutLineStatus.data && checkoutLines != null;
  bool get hasError => status == CheckoutLineStatus.error;
  bool get isEmpty => status == CheckoutLineStatus.empty;

  /// Get list of checkout lines
  List<CheckoutLine> get items => checkoutLines?.results ?? [];

  /// Get total count
  int get count => checkoutLines?.count ?? 0;

  /// Get total amount
  double get totalAmount => checkoutLines?.totalAmount ?? 0.0;

  /// Get total savings
  double get totalSavings => checkoutLines?.totalSavings ?? 0.0;

  /// Get total items (sum of quantities)
  int get totalItems => checkoutLines?.totalItems ?? 0;

  @override
  List<Object?> get props => [
    status,
    checkoutLines,
    errorMessage,
    lastSyncedAt,
    isRefreshing,
    refreshStartedAt,
    refreshEndedAt,
  ];

  CheckoutLineState copyWith({
    CheckoutLineStatus? status,
    CheckoutLinesResponse? checkoutLines,
    String? errorMessage,
    DateTime? lastSyncedAt,
    bool? isRefreshing,
    DateTime? refreshStartedAt,
    DateTime? refreshEndedAt,
    bool resetRefreshStartedAt = false,
    bool resetRefreshEndedAt = false,
  }) {
    return CheckoutLineState(
      status: status ?? this.status,
      checkoutLines: checkoutLines ?? this.checkoutLines,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshStartedAt: resetRefreshStartedAt
          ? null
          : (refreshStartedAt ?? this.refreshStartedAt),
      refreshEndedAt: resetRefreshEndedAt
          ? null
          : (refreshEndedAt ?? this.refreshEndedAt),
    );
  }
}
