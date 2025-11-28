import '../entities/coupon.dart';

/// Repository interface for coupon data operations
abstract class CouponRepository {
  /// Fetch coupon list with HTTP conditional request optimization
  /// Returns null if server responds with 304 Not Modified
  Future<CouponListResponse?> getCouponList({bool forceRefresh = false});
}
