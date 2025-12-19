# Delivery Status and Order Rating Flow Documentation

## Overview

This document describes the complete flow of delivery tracking and order rating system in the grocery app, from payment completion to final order rating.

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Complete User Flow](#complete-user-flow)
3. [Delivery Status Bar](#delivery-status-bar)
4. [Rating System](#rating-system)
5. [API Integration](#api-integration)
6. [State Management](#state-management)
7. [Error Handling](#error-handling)
8. [Testing Guide](#testing-guide)

---

## System Architecture

### Components Overview

```
Payment Success
    ↓
Delivery Tracking Starts
    ↓
DeliveryStatusBar (UI Component)
    ↓
Polling Backend Every 30s
    ↓
Status Updates (pending → assigned → at_pickup → picked_up → out_for_delivery → delivered)
    ↓
Rating Popup (Automatic)
    ↓
Rating Submission to Backend
```

### Key Files

| File | Purpose |
|------|---------|
| `confirm_order_screen.dart` | Order confirmation after payment |
| `delivery_status_bar.dart` | Visual status bar component |
| `delivery_status_provider.dart` | State management & business logic |
| `delivery_api.dart` | API calls for delivery status |
| `orders_screen.dart` | Order history & manual rating |
| `review_bottom_sheet.dart` | Rating UI component |
| `orders_api.dart` | API calls for order rating |

---

## Complete User Flow

### 1. Payment Success Flow

```
User completes payment
    ↓
Payment verification succeeds
    ↓
Order created in backend
    ↓
Navigate to ConfirmOrderScreen
    ↓
Start delivery tracking
    ↓
NO rating popup (removed from payment flow)
    ↓
Navigate back to home
    ↓
DeliveryStatusBar appears
```

**File:** `lib/features/cart/presentation/screen/confirm_order_screen.dart`

**Key Code:**
```dart
// Fetch latest order and start delivery tracking
await _fetchLatestOrderAndStartTracking();

// Start delivery tracking with real order ID
ref.read(deliveryStatusProvider.notifier)
   .startDeliveryTracking(latestOrder.id);

// Navigate back WITHOUT showing rating popup
Future<void> _handleBackNavigation() async {
  // Rating will be shown only when delivery status becomes "delivered"
  if (mounted) {
    context.go('/home');
  }
}
```

---

### 2. Delivery Tracking Flow

#### Step 1: Initial State - Waiting for Admin

```
Order created
    ↓
GET /api/delivery/v1/deliveries/?order={order_id}
    ↓
Response: { "count": 0, "results": [] }
    ↓
DeliveryStatusBar shows:
"Waiting for store to accept your order"
```

**File:** `lib/features/home/infrastructure/data_sources/remote/delivery_api.dart`

**Key Code:**
```dart
// Fetch deliveries list by order ID
final response = await _apiClient.get(
  ApiEndpoints.deliveriesByOrder(orderId),
);

final responseData = response.data as Map<String, dynamic>;
final results = responseData['results'] as List<dynamic>?;

// Empty results means admin hasn't accepted the order yet
if (results == null || results.isEmpty) {
  return null; // NOT an error
}
```

---

#### Step 2: Admin Accepts Order

```
Admin accepts order in backend
    ↓
Delivery record created
    ↓
Next polling cycle (30 seconds)
    ↓
GET /api/delivery/v1/deliveries/?order={order_id}
    ↓
Response: {
  "count": 1,
  "results": [{
    "id": 123,
    "status": "assigned",
    "order": 82,
    ...
  }]
}
    ↓
DeliveryStatusBar shows:
"Order accepted"
```

---

#### Step 3: Status Updates

**Delivery Status Enum:**

```dart
enum DeliveryApiStatus {
  pending,      // Initial state
  assigned,     // Admin accepted
  atPickup,     // Being packed
  pickedUp,     // Packed and ready
  outForDelivery, // Out for delivery
  delivered,    // Successfully delivered
  failed,       // Delivery failed
}
```

**Status Display Mapping:**

| Backend Status | UI Display | Est. Time |
|----------------|------------|-----------|
| `pending` | "Order accepted" | 40 mins |
| `assigned` | "Order accepted" | 40 mins |
| `at_pickup` | "Order is getting packed" | 30 mins |
| `picked_up` | "Order picked up" | 20 mins |
| `out_for_delivery` | "Out for delivery" | 10 mins |
| `delivered` | "Delivered successfully" | - |
| `failed` | "Delivery failed" | - |

**File:** `lib/features/home/domain/entities/delivery.dart`

---

#### Step 4: Polling Mechanism

```dart
// Polls every 30 seconds
Timer.periodic(Duration(seconds: 30), (_) {
  _fetchDeliveryStatus(orderId);
});

// Stops polling when:
// - Delivery is completed (delivered)
// - Delivery failed
// - User manually hides the status bar
```

**File:** `lib/features/home/application/providers/delivery_status_provider.dart`

---

### 3. DeliveryStatusBar Component

#### Visual States

**1. Loading State**
```
┌──────────────────────────────────────────┐
│ [⏳] Waiting for store to accept your   │
│      order                               │
│      Order #000082                       │
└──────────────────────────────────────────┘
```

**2. Active State**
```
┌──────────────────────────────────────────┐
│ [10mins] Order is getting packed      [→]│
│          Delivery person will contact    │
│          you soon..                      │
└──────────────────────────────────────────┘
```

**3. Completed State**
```
┌──────────────────────────────────────────┐
│ [✓] Order delivered!                  [×]│
│     Thank you for your order             │
└──────────────────────────────────────────┘
```

**4. Failed State**
```
┌──────────────────────────────────────────┐
│ [⚠] Delivery failed                   [×]│
│     Address was incorrect                │
└──────────────────────────────────────────┘
```

**File:** `lib/features/home/presentation/components/delivery_status_bar.dart`

---

### 4. Rating System Flow

#### Option 1: Automatic Rating Popup

```
Delivery status becomes "delivered"
    ↓
Wait 1 second
    ↓
ReviewBottomSheet appears automatically
    ↓
┌──────────────────────────────────────┐
│  [Review Image]                      │
│                                      │
│  How Was Your Experience            │
│                                      │
│  ┌─────────────────────────────┐    │
│  │ Rate Your Order             │    │
│  │ Delivered successfully      │    │
│  │                             │    │
│  │ ★ ★ ★ ★ ★                   │    │
│  └─────────────────────────────┘    │
│                                      │
│        [Submit Button]               │
└──────────────────────────────────────┘
    ↓
User selects stars (1-5)
    ↓
Taps "Submit"
    ↓
POST /api/order/v1/{order_id}/ratings/
Body: { "stars": 4 }
    ↓
Success: "Thank you for your rating!"
    ↓
Popup never appears again (flag: _feedbackShown = true)
```

**File:** `lib/features/home/application/providers/delivery_status_provider.dart`

**Key Code:**
```dart
// Triggered when status becomes "delivered"
case DeliveryApiStatus.delivered:
  state = DeliveryStatusState.completed(...);
  _stopPolling();
  _scheduleAutoHide();
  _showFeedbackPopup(); // Show rating popup
  break;

// Show feedback popup (only once)
void _showFeedbackPopup() {
  if (_feedbackShown || _context == null) return;

  _feedbackShown = true;

  Future.delayed(const Duration(seconds: 1), () {
    ReviewBottomSheet.show(_context!, ...).then((rating) async {
      if (rating != null && rating > 0) {
        await _submitRating(orderId, rating);
      }
    });
  });
}
```

---

#### Option 2: Manual Rating from Order History

```
User navigates to Orders screen
    ↓
Switch to "Previous" tab
    ↓
Expand delivered order
    ↓
┌──────────────────────────────────────┐
│ Order ID #000082                     │
│ 3 Items • Delivered                  │
│                                      │
│ ★ ★ ★ ☆ ☆  [Write a review]         │
│ Your Grocery Rating                  │
│                                      │
│        [Reorder Button]              │
└──────────────────────────────────────┘
    ↓
Tap "Write a review"
    ↓
Same ReviewBottomSheet appears
    ↓
Rating submitted to backend
```

**File:** `lib/features/orders/presentation/screens/orders_screen.dart`

**Key Code:**
```dart
Future<void> _handleWriteReview(OrderEntity order) async {
  // Validate order is completed
  if (!order.isCompleted) {
    AppSnackbar.warning(context,
      'You can only rate orders that have been delivered');
    return;
  }

  // Show review bottom sheet
  final rating = await ReviewBottomSheet.show(context, ...);

  // Submit rating
  if (rating != null && rating > 0) {
    await _submitOrderRating(order.id, rating);
  }
}
```

---

## API Integration

### 1. Delivery Status API

#### List Deliveries by Order
```http
GET /api/delivery/v1/deliveries/?order={order_id}
```

**Response (Admin not accepted):**
```json
{
  "count": 0,
  "results": []
}
```

**Response (Delivery exists):**
```json
{
  "count": 1,
  "results": [
    {
      "id": 123,
      "order": 82,
      "status": "assigned",
      "assigned_at": "2025-12-19T10:00:00Z",
      "picked_up_at": null,
      "delivered_at": null,
      "proof_of_delivery": null,
      "notes": null
    }
  ]
}
```

**Endpoint:** `lib/core/network/endpoints.dart`
```dart
static String deliveriesByOrder(int orderId) =>
    '/api/delivery/v1/deliveries/?order=$orderId';
```

---

### 2. Order Rating API

#### Submit Rating
```http
POST /api/order/v1/{order_id}/ratings/
Content-Type: application/json

{
  "stars": 4,
  "body": "Great service!"  // Optional
}
```

**Success Response (201 Created):**
```json
{
  "id": 1,
  "user": 1,
  "order": 82,
  "stars": 4,
  "body": "Great service!",
  "created_at": "2025-12-19T08:35:01.026834Z",
  "updated_at": "2025-12-19T08:35:01.026854Z"
}
```

**Error Response (403 Forbidden):**
```json
{
  "detail": "You can only rate your own completed orders"
}
```

**Endpoint:** `lib/core/network/endpoints.dart`
```dart
static String orderRating(String orderId) =>
    '/api/order/v1/$orderId/ratings/';
```

---

### 3. Admin Phone API

#### Get Support Phone Number
```http
GET /api/accounts/v1/admin/phone/
```

**Success Response:**
```json
{
  "phone": "+918089262564"
}
```

**Fallback:** `+918089262564` (hardcoded in app)

**Endpoint:** `lib/core/network/endpoints.dart`
```dart
static const String adminPhone = '/api/accounts/v1/admin/phone/';
```

---

## State Management

### Delivery Status States

```dart
@freezed
class DeliveryStatusState with _$DeliveryStatusState {
  // Bar is hidden (no active delivery)
  const factory DeliveryStatusState.hidden() = DeliveryStatusHidden;

  // Fetching delivery status
  const factory DeliveryStatusState.loading({
    required int orderId
  }) = DeliveryStatusLoading;

  // Order is being processed/delivered
  const factory DeliveryStatusState.active({
    required int orderId,
    required DeliveryApiStatus status,
    required DeliveryEntity delivery,
  }) = DeliveryStatusActive;

  // Order delivered successfully
  const factory DeliveryStatusState.completed({
    required int orderId,
    required DeliveryEntity delivery,
  }) = DeliveryStatusCompleted;

  // Delivery failed
  const factory DeliveryStatusState.failed({
    required int orderId,
    required DeliveryEntity delivery,
    String? failureReason,
  }) = DeliveryStatusFailed;

  // Error fetching delivery status
  const factory DeliveryStatusState.error({
    required int orderId,
    required String message,
  }) = DeliveryStatusError;
}
```

**File:** `lib/features/home/application/states/delivery_status_state.dart`

---

### Provider Structure

```dart
// Main delivery status provider
final deliveryStatusProvider =
    StateNotifierProvider<DeliveryStatusNotifier, DeliveryStatusState>(
  (ref) {
    final deliveryApi = ref.watch(deliveryApiProvider);
    final ordersApi = ref.watch(ordersApiProvider);
    return DeliveryStatusNotifier(deliveryApi, ordersApi);
  }
);

// Visibility selector
final isDeliveryVisibleProvider = Provider<bool>((ref) {
  final status = ref.watch(deliveryStatusProvider);
  return status.isVisible;
});

// Current status selector
final currentDeliveryStatusProvider = Provider<DeliveryApiStatus?>((ref) {
  final status = ref.watch(deliveryStatusProvider);
  return status.currentStatus;
});

// Delivery entity selector
final currentDeliveryProvider = Provider<DeliveryEntity?>((ref) {
  final status = ref.watch(deliveryStatusProvider);
  return status.delivery;
});
```

---

## Error Handling

### 1. Empty Delivery List (Admin Not Accepted)

**Condition:** Backend returns `{ "results": [] }`

**Handling:**
- ✅ Returns `null` from API layer
- ✅ Shows "Waiting for store to accept your order"
- ✅ Continues polling
- ✅ No error UI or logs

**Code:**
```dart
if (results == null || results.isEmpty) {
  return null; // NOT an error
}
```

---

### 2. 404 Error

**Condition:** Delivery endpoint returns 404

**Handling:**
- ✅ Returns `null` (treated as "not yet created")
- ✅ No error UI
- ✅ Continues polling

**Code:**
```dart
on DioException catch (e) {
  // Return null for 404 (delivery not yet created) - NOT an error
  if (e.response?.statusCode == 404) {
    return null;
  }
  // Rethrow other errors
  throw Exception('Error fetching delivery status: ${e.message}');
}
```

---

### 3. Network Errors

**Condition:** No internet, timeout, server error

**Handling:**
- ✅ Shows error state in DeliveryStatusBar
- ✅ Provides "Tap to retry" option
- ✅ Logs error for debugging
- ✅ App continues normally

**UI:**
```
┌──────────────────────────────────────┐
│ [⚠] Unable to fetch status      [↻] │
│     Tap to retry                     │
└──────────────────────────────────────┘
```

---

### 4. Rating Submission Errors

**Condition:** Rating API fails

**Handling:**
- ✅ Shows user-friendly error message
- ✅ App doesn't crash
- ✅ User can try again from Order History

**Error Messages:**
| Error Type | Message |
|------------|---------|
| 403 Forbidden | "You can only rate your own completed orders" |
| Network Error | "Failed to submit rating. Please try again later." |
| Other | "Failed to submit rating. Please try again later." |

---

## Testing Guide

### Test Case 1: Complete Happy Path

```
1. Complete payment for an order
   ✓ Order confirmation screen appears
   ✓ Delivery tracking starts
   ✓ NO rating popup appears

2. Navigate back to home
   ✓ DeliveryStatusBar appears
   ✓ Shows "Waiting for store to accept your order"

3. Admin accepts order (backend)
   ✓ Status updates to "Order accepted" within 30 seconds

4. Admin updates status through delivery flow
   ✓ Status updates automatically every 30 seconds
   ✓ Shows: assigned → at_pickup → picked_up → out_for_delivery

5. Admin marks as delivered
   ✓ Status becomes "Delivered successfully"
   ✓ Wait 1 second
   ✓ Rating popup appears automatically

6. User rates with 5 stars
   ✓ Success message: "Thank you for your rating!"
   ✓ Rating saved in backend

7. Check Order History
   ✓ Order shows in "Previous" tab
   ✓ Star rating UI reflects previous rating
```

---

### Test Case 2: User Skips Popup, Rates Later

```
1. Complete delivery (status = delivered)
   ✓ Rating popup appears

2. User closes popup without rating
   ✓ Popup closes
   ✓ No rating submitted

3. Navigate to Orders screen
   ✓ Switch to "Previous" tab
   ✓ Delivered order appears

4. Tap "Write a review"
   ✓ Same rating popup appears
   ✓ Shows order details and delivery date

5. User selects 4 stars
   ✓ Success message appears
   ✓ Rating submitted to backend
```

---

### Test Case 3: Network Error Handling

```
1. Disable internet connection

2. Complete payment
   ✓ Delivery tracking starts
   ✓ Error state appears after timeout

3. Tap "Tap to retry" in error bar
   ✓ Loading state appears
   ✓ Error persists (no internet)

4. Enable internet connection

5. Tap "Tap to retry" again
   ✓ Status fetched successfully
   ✓ Shows current delivery status
```

---

### Test Case 4: Rating Validation

```
1. Navigate to Orders screen
2. Try to rate an ACTIVE order
   ✓ Warning: "You can only rate orders that have been delivered"
   ✓ No popup appears

3. Try to rate a CANCELLED order
   ✓ Same warning appears
   ✓ No popup appears

4. Try to rate a DELIVERED order
   ✓ Rating popup appears
   ✓ Allows rating
```

---

### Test Case 5: Multiple Orders

```
1. Complete payment for Order #1
   ✓ Tracking starts for Order #1

2. Complete payment for Order #2
   ✓ Tracking switches to Order #2
   ✓ Old polling stopped
   ✓ New polling started

3. Both orders get delivered
   ✓ Rating popup appears only for most recent delivery
   ✓ Flag prevents duplicate popups

4. Rate from Order History
   ✓ Can rate Order #1 manually
   ✓ Can rate Order #2 manually
```

---

## Performance Considerations

### 1. Polling Optimization

- ✅ 30-second interval (not too frequent)
- ✅ Stops polling when delivered/failed
- ✅ Only one active polling timer at a time
- ✅ Polling paused when app in background

---

### 2. Caching

**Admin Phone Number:**
- ✅ Cached after first fetch
- ✅ Single API call per session
- ✅ Manual cache clear available

**Delivery Status:**
- ❌ Not cached (needs real-time updates)
- ✅ Polling ensures fresh data

---

### 3. Memory Management

- ✅ Timers properly disposed
- ✅ State reset when hiding status bar
- ✅ Listeners cleaned up on dispose
- ✅ Context validated before UI updates

---

## Security Considerations

### 1. Order Ownership Validation

- ✅ Backend validates user can only rate their own orders
- ✅ 403 error if attempting to rate others' orders
- ✅ Frontend shows user-friendly error message

---

### 2. Input Validation

**Star Rating:**
- ✅ Must be between 1-5
- ✅ Validated before API call
- ✅ 0 or null treated as "no rating"

**Order Status:**
- ✅ Only delivered orders can be rated
- ✅ Frontend validates before showing popup
- ✅ Backend double-checks status

---

### 3. API Security

- ✅ All API calls require authentication
- ✅ Order ID validated on backend
- ✅ User ID from auth token, not request body
- ✅ Rate limiting on backend (recommended)

---

## Troubleshooting

### Issue: Status bar doesn't appear after payment

**Possible causes:**
1. Order creation failed
2. Delivery tracking not started
3. API call failed

**Debug steps:**
```dart
// Check logs for:
Logger.info('Starting delivery tracking for order: $orderId');
Logger.info('Delivery not yet assigned for order: $orderId');
Logger.error('Error fetching delivery status: $e');
```

---

### Issue: Rating popup appears multiple times

**Possible causes:**
1. `_feedbackShown` flag not set
2. Multiple delivery status changes

**Fix:**
```dart
// Ensure flag is set before showing popup
_feedbackShown = true;

// Reset flag only when starting new order tracking
void startDeliveryTracking(int orderId) {
  _feedbackShown = false; // Reset for new order
  ...
}
```

---

### Issue: Status stuck on "Waiting for store to accept"

**Possible causes:**
1. Admin hasn't accepted order yet (expected)
2. Backend not creating delivery record
3. API returning wrong data

**Debug steps:**
1. Check backend admin panel
2. Verify order status
3. Check API response in logs
4. Manually trigger delivery creation

---

### Issue: Rating submission fails

**Possible causes:**
1. Order not delivered (backend validation)
2. Network error
3. Invalid order ID
4. Permission error

**Debug steps:**
```dart
Logger.error('Failed to submit order rating', error: e);

// Check for specific error messages:
if (e.toString().contains('only rate your own')) {
  // Permission issue
}
```

---

## Future Enhancements

### Potential Improvements

1. **Review Text Support:**
   - Add text input field to ReviewBottomSheet
   - Submit both stars and text to backend
   - Display reviews in order details

2. **Update Existing Ratings:**
   - Detect if rating already exists
   - Use PATCH instead of POST
   - Allow users to modify their ratings

3. **Real-time Updates:**
   - WebSocket connection for instant status updates
   - Remove polling delay
   - Better user experience

4. **Delivery Person Details:**
   - Show delivery person name and photo
   - Add call delivery person button
   - Show real-time location tracking

5. **Push Notifications:**
   - Notify user when order accepted
   - Notify when out for delivery
   - Notify when delivered

6. **Estimated Time Accuracy:**
   - Calculate based on actual distance
   - Update based on real-time traffic
   - Show countdown timer

---

## Conclusion

This delivery and rating system provides:

✅ **Complete Flow:** From payment to final rating
✅ **Real-time Updates:** 30-second polling for status changes
✅ **Two Rating Options:** Automatic popup + manual from history
✅ **Error Resilience:** Graceful handling of all edge cases
✅ **User Experience:** Clear feedback at every step
✅ **Backend Integration:** Proper API usage with validation
✅ **State Management:** Clean separation of concerns
✅ **Production Ready:** Comprehensive error handling and logging

---

**Last Updated:** December 19, 2025
**Version:** 1.0
**Maintained by:** Development Team
