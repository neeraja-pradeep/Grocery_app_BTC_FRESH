import '../../domain/entities/checkout.dart';

class CheckoutModel extends Checkout {
  CheckoutModel({
    required super.id,
    required super.user,
    required super.createdAt,
    required super.coupon,
  });

  factory CheckoutModel.fromJson(Map<String, dynamic> json) {
    return CheckoutModel(
      id: json['id'] as int,
      user: json['user'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      coupon: json['coupon'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'created_at': createdAt.toIso8601String(),
      //'coupon' : 0
    };
  }
}

// Response with coupon :
// {
//   "coupon": [
//     "Invalid pk \"0\" - object does not exist."
//   ]
// }
