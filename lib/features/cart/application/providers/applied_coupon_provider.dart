import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/coupon.dart';

/// State for the currently applied coupon
class AppliedCouponState {
  const AppliedCouponState({this.appliedCoupon, this.discountAmount = 0.0});

  final Coupon? appliedCoupon;
  final double discountAmount;

  bool get hasCoupon => appliedCoupon != null;

  String get couponCode => appliedCoupon?.name ?? '';

  double get discountPercentage {
    if (appliedCoupon == null) return 0.0;
    return double.tryParse(appliedCoupon!.discountPercentage) ?? 0.0;
  }

  AppliedCouponState copyWith({
    Coupon? appliedCoupon,
    double? discountAmount,
    bool clearCoupon = false,
  }) {
    return AppliedCouponState(
      appliedCoupon: clearCoupon ? null : (appliedCoupon ?? this.appliedCoupon),
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }
}

/// Controller for managing applied coupon
class AppliedCouponController extends Notifier<AppliedCouponState> {
  @override
  AppliedCouponState build() {
    return const AppliedCouponState();
  }

  /// Apply a coupon and calculate discount based on item total
  void applyCoupon(Coupon coupon, double itemTotal) {
    final discountPercentage =
        double.tryParse(coupon.discountPercentage) ?? 0.0;
    final discountAmount = itemTotal * (discountPercentage / 100);

    state = AppliedCouponState(
      appliedCoupon: coupon,
      discountAmount: discountAmount,
    );
  }

  /// Update discount amount when item total changes
  void updateDiscount(double itemTotal) {
    if (state.appliedCoupon == null) return;

    final discountPercentage =
        double.tryParse(state.appliedCoupon!.discountPercentage) ?? 0.0;
    final discountAmount = itemTotal * (discountPercentage / 100);

    state = state.copyWith(discountAmount: discountAmount);
  }

  /// Remove applied coupon
  void removeCoupon() {
    state = const AppliedCouponState();
  }

  /// Calculate discount for a given item total
  double calculateDiscount(double itemTotal) {
    if (state.appliedCoupon == null) return 0.0;
    final discountPercentage =
        double.tryParse(state.appliedCoupon!.discountPercentage) ?? 0.0;
    return itemTotal * (discountPercentage / 100);
  }
}

/// Provider for applied coupon state
final appliedCouponProvider =
    NotifierProvider<AppliedCouponController, AppliedCouponState>(
      AppliedCouponController.new,
    );
