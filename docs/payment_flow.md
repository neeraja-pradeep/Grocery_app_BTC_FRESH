# Payment Flow - Complete Documentation

## Overview

The Payment Flow handles the complete checkout process from cart to order confirmation, integrating with Razorpay for payment processing. It manages cart validation, address selection, payment initiation, verification, and post-payment navigation.

---

## Architecture

### Files Involved

```
lib/
├── features/
│   ├── cart/
│   │   ├── application/
│   │   │   └── providers/
│   │   │       ├── checkout_line_provider.dart    # Cart state management
│   │   │       └── payment_provider.dart          # Payment logic & Razorpay
│   │   ├── infrastructure/
│   │   │   └── data_sources/
│   │   │       └── remote/
│   │   │           └── checkout_line_data_source.dart
│   │   └── presentation/
│   │       └── screen/
│   │           ├── cart_screen.dart               # Cart display
│   │           ├── checkout_screen.dart           # Place order
│   │           ├── confirm_order_screen.dart      # Success screen
│   │           └── failed_order_screen.dart       # Failure screen
│   ├── address/
│   │   └── application/
│   │       └── providers/
│   │           └── address_provider.dart          # Address management
│   └── home/
│       └── application/
│           └── providers/
│               └── delivery_status_provider.dart  # Post-order tracking
└── core/
    └── network/
        └── endpoints.dart                         # API endpoints
```

---

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            PAYMENT FLOW                                      │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐
│   CartScreen     │
│                  │
│  User reviews    │
│  cart items      │
│                  │
│  Taps            │
│  "Checkout"      │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  CheckoutScreen                                               │
│                                                               │
│  1. Display cart summary                                      │
│  2. Show selected delivery address                            │
│  3. Show total amount                                         │
│  4. "Place Order" button                                      │
└────────┬─────────────────────────────────────────────────────┘
         │ User taps "Place Order"
         ▼
┌──────────────────────────────────────────────────────────────┐
│  _handlePlaceOrder()                                          │
│                                                               │
│  Validation Steps:                                            │
│  1. Check address selected                                    │
│     if (!hasAddress) → Show "Select delivery address"         │
│                                                               │
│  2. Refresh cart to verify latest data                        │
│     await checkoutLineNotifier.refreshCart()                  │
│                                                               │
│  3. Validate cart not empty                                   │
│     if (cart.isEmpty) → Show "Cart is empty"                  │
│                                                               │
│  4. Validate stock availability                               │
│     for (item in cart) {                                      │
│       if (item.quantity > item.availableStock)                │
│         → Show "Some items are out of stock"                  │
│     }                                                         │
└────────┬─────────────────────────────────────────────────────┘
         │ All validations passed
         ▼
┌──────────────────────────────────────────────────────────────┐
│  PaymentController.initiatePayment()                          │
│                                                               │
│  1. Call: POST /api/order/v1/checkout/                        │
│     Request: { /* cart data */ }                              │
│                                                               │
│  2. Backend Response:                                         │
│     {                                                         │
│       "razorpay_order_id": "order_xyz123",                    │
│       "amount": 50000,  // in paise                           │
│       "currency": "INR",                                      │
│       "order_id": 66,   // Internal order ID                  │
│       "key": "rzp_test_...",                                  │
│     }                                                         │
└────────┬─────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  Launch Razorpay Checkout                                     │
│                                                               │
│  Razorpay.open({                                              │
│    key: response.key,                                         │
│    amount: response.amount,                                   │
│    order_id: response.razorpay_order_id,                      │
│    name: 'BTC Grocery',                                       │
│    description: 'Order Payment',                              │
│    prefill: {                                                 │
│      contact: user.phone,                                     │
│      email: user.email,                                       │
│    },                                                         │
│    theme: { color: '#4CAF50' },                               │
│  });                                                          │
└────────┬────────────────────────────┬────────────────────────┘
         │                            │
         │ onSuccess                  │ onFailure
         ▼                            ▼
┌────────────────────┐      ┌────────────────────────┐
│  _handleSuccess()  │      │  _handleFailure()      │
│                    │      │                        │
│  1. Extract IDs:   │      │  1. Log error          │
│     - payment_id   │      │  2. Show error message │
│     - order_id     │      │  3. Navigate:          │
│     - signature    │      │     context.push(      │
│  2. Verify payment │      │       '/order-failed', │
│  3. Create order   │      │     )                  │
└────────┬───────────┘      └────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  PaymentController.verifyPayment()                            │
│                                                               │
│  1. Call: POST /api/order/v1/payment/verify/                  │
│     Request: {                                                │
│       "razorpay_payment_id": "pay_xyz",                       │
│       "razorpay_order_id": "order_xyz",                       │
│       "razorpay_signature": "abc123...",                      │
│     }                                                         │
│                                                               │
│  2. Backend verifies signature using Razorpay secret          │
│  3. Creates order in database                                 │
│  4. Clears user's cart                                        │
│  5. Returns: { "success": true, "order_id": 66 }              │
└────────┬─────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  Navigation: Payment Success                                  │
│                                                               │
│  context.go('/order-success')                                 │
│  └─► Replaces navigation stack                               │
│      (Prevents back to checkout)                              │
└────────┬─────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  ConfirmOrderScreen                                           │
│                                                               │
│  1. Show success animation                                    │
│  2. Display order details                                     │
│  3. Show "Order confirmed" message                            │
│  4. Start delivery tracking:                                  │
│     deliveryStatusProvider.startDeliveryTracking(orderId)     │
│  5. "Back" button → Rating sheet → Navigate to Home           │
└───────────────────────────────────────────────────────────────┘
```

---

## API Integration

### 1. Initiate Payment

**Endpoint:**
```
POST /api/order/v1/checkout/
```

**Request:**
```json
{
  "checkout_lines": [
    {
      "product_variant_id": 2,
      "quantity": 3
    }
  ],
  "delivery_address_id": 51
}
```

**Response:**
```json
{
  "razorpay_order_id": "order_N8x7YzKqP9mZpQ",
  "amount": 50000,
  "currency": "INR",
  "order_id": 66,
  "key": "rzp_test_1DP5mmOlF5G5ag",
  "notes": {
    "order_id": "66",
    "user_id": "51269"
  }
}
```

### 2. Verify Payment

**Endpoint:**
```
POST /api/order/v1/payment/verify/
```

**Request:**
```json
{
  "razorpay_payment_id": "pay_N8x8ABcDef1234",
  "razorpay_order_id": "order_N8x7YzKqP9mZpQ",
  "razorpay_signature": "9d1234567890abcdef1234567890abcdef123456"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Payment verified successfully",
  "order_id": 66,
  "order": {
    "id": 66,
    "status": "pending",
    "total": "500.00",
    "created_at": "2025-12-19T10:30:00Z"
  }
}
```

**Response (Failure):**
```json
{
  "success": false,
  "error": "Invalid signature",
  "message": "Payment verification failed"
}
```

---

## State Management

### Payment Provider

```dart
final paymentControllerProvider = StateNotifierProvider<PaymentController, PaymentState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final razorpay = ref.watch(razorpayProvider);
  return PaymentController(apiClient, razorpay);
});
```

### Payment State (Freezed)

```dart
@freezed
class PaymentState with _$PaymentState {
  const factory PaymentState.initial() = _Initial;
  const factory PaymentState.loading() = _Loading;
  const factory PaymentState.success({
    required String orderId,
    required String paymentId,
  }) = _Success;
  const factory PaymentState.failure({
    required String error,
  }) = _Failure;
}
```

### Cart Provider

```dart
final checkoutLineControllerProvider =
    StateNotifierProvider<CheckoutLineController, CheckoutLineState>((ref) {
  return CheckoutLineController(ref.watch(checkoutLineDataSourceProvider));
});
```

**Key Methods:**
- `refreshCart()` - Reload cart from API before payment
- `clearCart()` - Called after successful payment (via API)

### Address Provider

```dart
final profileAddressControllerProvider =
    StateNotifierProvider<ProfileAddressController, AddressState>((ref) {
  return ProfileAddressController(ref.watch(addressApiProvider));
});
```

**Used to:**
- Get selected delivery address
- Validate address before payment

---

## Razorpay Integration

### Initialization

```dart
class PaymentController extends StateNotifier<PaymentState> {
  final Razorpay _razorpay;
  final ApiClient _apiClient;

  PaymentController(this._apiClient, this._razorpay) : super(const PaymentState.initial()) {
    // Setup Razorpay event listeners
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();  // Clear event listeners
    super.dispose();
  }
}
```

### Payment Options

```dart
var options = {
  'key': checkoutResponse.key,
  'amount': checkoutResponse.amount,  // In paise
  'currency': checkoutResponse.currency,
  'name': 'BTC Grocery',
  'description': 'Order Payment',
  'order_id': checkoutResponse.razorpayOrderId,
  'prefill': {
    'contact': userPhone,
    'email': userEmail,
  },
  'theme': {
    'color': '#4CAF50',  // App green color
  },
  'retry': {
    'enabled': true,
    'max_count': 3,
  },
  'modal': {
    'confirm_close': true,  // Confirm before closing payment screen
  },
};

_razorpay.open(options);
```

### Event Handlers

**Success:**
```dart
void _handlePaymentSuccess(PaymentSuccessResponse response) {
  final paymentId = response.paymentId;
  final orderId = response.orderId;
  final signature = response.signature;

  // Verify payment on backend
  verifyPayment(
    razorpayPaymentId: paymentId,
    razorpayOrderId: orderId,
    razorpaySignature: signature,
  );
}
```

**Error:**
```dart
void _handlePaymentError(PaymentFailureResponse response) {
  state = PaymentState.failure(
    error: response.message ?? 'Payment failed',
  );

  Logger.error('Payment failed', error: response.message);
}
```

**External Wallet:**
```dart
void _handleExternalWallet(ExternalWalletResponse response) {
  Logger.info('External wallet selected: ${response.walletName}');
  // Handle wallet payment (e.g., Paytm, PhonePe)
}
```

---

## Validation Flow

### Pre-Payment Validations

```dart
Future<void> _handlePlaceOrder() async {
  // 1. Address validation
  final selectedAddress = ref.read(selectedAddressProvider);
  if (selectedAddress == null) {
    AppSnackbar.error(context, 'Please select a delivery address');
    return;
  }

  // 2. Refresh cart to ensure latest data
  setState(() => _isLoading = true);
  await ref.read(checkoutLineControllerProvider.notifier).refreshCart();

  // 3. Cart empty check
  final cartState = ref.read(checkoutLineControllerProvider);
  if (cartState.items.isEmpty) {
    AppSnackbar.error(context, 'Your cart is empty');
    setState(() => _isLoading = false);
    return;
  }

  // 4. Stock availability check
  bool hasStockIssue = false;
  for (final item in cartState.items) {
    if (item.quantity > item.productDetails.currentQuantity) {
      hasStockIssue = true;
      break;
    }
  }

  if (hasStockIssue) {
    AppSnackbar.error(
      context,
      'Some items are out of stock. Please update your cart.',
    );
    setState(() => _isLoading = false);
    return;
  }

  // 5. Initiate payment
  await _initiatePayment();
}
```

### Post-Payment Verification

Backend verification flow:
1. Extract signature from Razorpay response
2. Generate expected signature: `HMAC_SHA256(order_id|payment_id, secret)`
3. Compare signatures
4. If match → Create order, clear cart, return success
5. If mismatch → Return error, don't create order

---

## Navigation Strategy

### Route Definitions

```dart
GoRoute(
  path: '/checkout',
  builder: (_, state) => const CheckoutScreen(),
),
GoRoute(
  path: '/order-success',
  builder: (_, state) => const ConfirmOrderScreen(),
),
GoRoute(
  path: '/order-failed',
  builder: (_, state) {
    final errorMessage = state.extra as String?;
    return FailedOrderScreen(errorMessage: errorMessage);
  },
),
```

### Navigation Methods

| Scenario | Method | Stack Behavior |
|----------|--------|----------------|
| Payment Success | `context.go('/order-success')` | **Replace** - Prevents back to checkout |
| Payment Failure | `context.push('/order-failed')` | **Push** - Allows back to cart |
| From Success to Home | `context.go('/home')` | **Replace** - Clean navigation |
| From Failure to Cart | `BottomNavigation.globalKey.currentState?.navigateToTab(3)` | **Navigate tab** - Via bottom nav |

**Why different methods?**
- **Success:** User shouldn't go back to checkout (payment already processed)
- **Failure:** User should retry from cart (no payment made)

---

## Error Handling

### Payment Errors

```dart
// Network errors
try {
  await paymentController.initiatePayment();
} on DioException catch (e) {
  if (e.response?.statusCode == 400) {
    AppSnackbar.error(context, 'Invalid cart data');
  } else if (e.response?.statusCode == 401) {
    AppSnackbar.error(context, 'Please log in again');
    context.go('/login');
  } else {
    AppSnackbar.error(context, 'Network error. Please try again.');
  }
}

// Razorpay errors
void _handlePaymentError(PaymentFailureResponse response) {
  final error = response.message ?? 'Payment failed';

  if (error.contains('cancelled')) {
    AppSnackbar.info(context, 'Payment cancelled by user');
  } else if (error.contains('network')) {
    AppSnackbar.error(context, 'Network error. Please check connection.');
  } else {
    AppSnackbar.error(context, 'Payment failed: $error');
  }

  context.push('/order-failed', extra: error);
}
```

### Cart Reservation Expiry

```dart
// In failed_order_screen.dart
class FailedOrderScreen extends StatelessWidget {
  final bool isReservationExpired;

  String get _message {
    if (isReservationExpired) {
      return 'Your cart reservation expired. If payment was deducted, '
             'it will be refunded automatically within 5-7 business days.';
    }
    return 'Payment failed. Please try again.';
  }

  // "Go to Cart" button
  ElevatedButton(
    onPressed: () {
      Navigator.of(context).popUntil((route) => route.isFirst);
      BottomNavigation.globalKey.currentState?.navigateToTab(3);
    },
    child: Text('Go to cart'),
  ),
}
```

---

## Security Considerations

### 1. Server-Side Signature Verification

**CRITICAL:** Payment verification must happen on backend
```python
# Backend (Django/Python example)
import hmac
import hashlib

def verify_razorpay_signature(order_id, payment_id, signature):
    secret = settings.RAZORPAY_SECRET
    message = f"{order_id}|{payment_id}"
    generated_signature = hmac.new(
        secret.encode(),
        message.encode(),
        hashlib.sha256
    ).hexdigest()

    return hmac.compare_digest(generated_signature, signature)
```

**Why?**
- Client-side verification can be bypassed
- Secret key must never be in client code
- Server controls order creation

### 2. Cart Validation Before Payment

```dart
// Always refresh cart before initiating payment
await checkoutLineNotifier.refreshCart();

// Verify stock availability
for (final item in cartState.items) {
  if (item.quantity > item.productDetails.currentQuantity) {
    // Prevent payment if out of stock
  }
}
```

### 3. Idempotency

Backend should handle duplicate payment verifications:
```python
# Check if order already created for this payment
existing_order = Order.objects.filter(
    razorpay_payment_id=payment_id
).first()

if existing_order:
    return {'success': True, 'order_id': existing_order.id}

# Create new order only if doesn't exist
```

---

## Testing the Flow

### Manual Test Steps

1. **Add items to cart:**
   - Add multiple products with different quantities
   - Verify cart total calculation

2. **Navigate to checkout:**
   - Tap "Checkout" from cart
   - Verify checkout screen displays correct items & total

3. **Address validation:**
   - Try placing order without address → Should show error
   - Select delivery address
   - Verify address displayed on checkout screen

4. **Initiate payment:**
   - Tap "Place Order"
   - Observe: Razorpay checkout opens
   - Verify order details (amount, description)

5. **Payment success:**
   - Complete payment using test card
   - Observe: Navigated to ConfirmOrderScreen
   - Verify: Order details displayed
   - Check: Delivery tracking started

6. **Payment failure:**
   - Cancel payment or use invalid card
   - Observe: Navigated to FailedOrderScreen
   - Tap "Go to Cart" → Should navigate to cart tab
   - Verify: Cart items still present

7. **Post-payment:**
   - From success screen, tap "Back"
   - Observe: Rating sheet (if configured)
   - Navigate to Home
   - Verify: Delivery status bar visible

### Test Cards (Razorpay Test Mode)

**Success:**
- Card: 4111 1111 1111 1111
- CVV: Any 3 digits
- Expiry: Any future date

**Failure:**
- Card: 4000 0000 0000 0002
- This card will always fail

### Debug Logging

```dart
// In payment_controller.dart
Logger.info('Payment initiated', data: {
  'razorpay_order_id': response.razorpayOrderId,
  'amount': response.amount,
  'currency': response.currency,
});

Logger.info('Payment success', data: {
  'payment_id': paymentId,
  'order_id': orderId,
});

Logger.error('Payment failed', error: response.message);
```

---

## Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Payment sheet doesn't open | Razorpay not initialized | Check Razorpay setup in pubspec.yaml |
| "Signature verification failed" | Wrong secret key | Verify backend uses correct Razorpay secret |
| Cart empty after failed payment | Cart cleared on failure | Only clear cart on successful verification |
| Can go back to checkout after payment | Using `push` instead of `go` | Use `context.go()` for success navigation |
| Duplicate orders created | No idempotency check | Add payment_id uniqueness constraint |
| Stock issues during payment | Stale cart data | Always refresh cart before payment |

---

## Future Enhancements

1. **Multiple Payment Methods:**
   - UPI direct integration
   - Wallets (Paytm, PhonePe)
   - Cash on Delivery (COD)
   - Net Banking

2. **Payment Retry Logic:**
   - Auto-retry on network failures
   - Save payment options for quick retry
   - Resume payment after app restart

3. **Split Payments:**
   - Partial payment with wallet + card
   - EMI options for large orders

4. **Payment Analytics:**
   - Track payment success rates
   - Monitor common failure reasons
   - A/B test checkout flow

5. **Enhanced Security:**
   - Device fingerprinting
   - Fraud detection
   - 3D Secure authentication

6. **User Experience:**
   - Save payment methods
   - One-tap checkout
   - Payment reminders for abandoned carts

---

## Related Documentation

- [Delivery Status Flow](./delivery_status_flow.md)
- [Reorder Flow](./reorder_flow.md)
- [Cart Management](../features/cart/README.md)
- [API Integration](./API%20Integration%20Document%20-%20BTC%20Grocery.md)
- [Razorpay Debug Guide](../RAZORPAY_DEBUG_VS_RELEASE.md)
