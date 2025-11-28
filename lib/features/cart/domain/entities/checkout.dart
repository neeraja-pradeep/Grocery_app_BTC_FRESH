class Checkout {
  final int id;
  final int user;
  final DateTime createdAt;
  final int? coupon;

  Checkout({
    required this.id,
    required this.user,
    required this.createdAt,
    required this.coupon,
  });
}
