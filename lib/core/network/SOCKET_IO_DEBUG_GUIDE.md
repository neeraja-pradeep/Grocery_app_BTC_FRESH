# Socket.IO Debug Guide

## Step 1: Verify Installation

Run this to ensure socket_io_client is installed:

```bash
flutter pub get
```

Check pubspec.lock contains `socket_io_client: ^2.0.3`

---

## Step 2: Check Console Logs

When you run the app, you should see these logs in the console:

### ✅ Successful Connection Sequence

```
[INFO] 🔧 Initializing Socket.IO service...
[INFO] 🔌 Attempting to connect to Socket.IO at: http://156.67.104.149:8080/
[INFO] ✅ Socket.IO initialization complete
[INFO] 📋 Registering event listeners...
[INFO] ✅ All event listeners registered
[INFO] 🟢 Socket.IO Connected! ID: [socket-id-here]
```

### ❌ Connection Problems

If you see:
```
[WARN] ⚠️ Socket not connected. Cannot join variant room 5
```
→ **Problem**: Socket hasn't connected yet before joining rooms

If you see:
```
[ERROR] ❌ Socket.IO Connection Error: ...
```
→ **Problem**: Connection failed (check backend URL and server status)

---

## Step 3: Verify Backend Server

Check if your Django Socket.IO server is running:

```bash
# Test if server is accessible
curl -i http://156.67.104.149:8080/socket.io/?EIO=4&transport=websocket

# Should respond with Socket.IO connection
```

---

## Step 4: Test Price Update Flow

### 4a. Join a Variant Room

When you open a product screen with variant ID = 5, you should see:

```
[INFO] 📍 Requested to join variant room: 5
[INFO] ✅ Room Joined: {...}
```

### 4b. Server Sends Price Update

When backend emits `price_update` event, you should see:

```
[INFO] 🔥 Price Update Received: {
  "variant_id": 5,
  "new_price": 900.0,
  "old_price": 1000.0,
  "discounted_price": 750.0
}
[INFO] 🔥 Processing price update: {...}
[INFO] ✅ Price update applied: PriceUpdateEvent(variantId: 5, newPrice: 900.0, ...)
```

### 4c. UI Updates

The product card should show:
- New price: `$900.00` (green)
- Old price: `$1000.00` (crossed out, grey)
- Sync icon indicator (blue circle with refresh icon)

---

## Step 5: Test Inventory Update Flow

### 5a. Server Sends Inventory Update

When backend emits `inventory_update` event, you should see:

```
[INFO] 📦 Inventory Update Received: {
  "variant_id": 5,
  "current_quantity": 22,
  "previous_quantity": 25,
  "current_stock_unit": "units",
  "warehouse_id": 1
}
[INFO] 📦 Processing inventory update: {...}
[INFO] ✅ Inventory update applied: InventoryUpdateEvent(variantId: 5, currentQuantity: 22, ...)
```

### 5b. UI Updates

The product card should show:
- Stock badge changes color:
  - **Green**: quantity > 5
  - **Orange**: quantity < 5
  - **Red**: quantity = 0 (Out of Stock)
- Shows: "In Stock", "Only 4 left", or "Out of Stock"
- Sync icon indicator appears

---

## Step 6: Manual Testing with Backend

### Test Price Update from Django

```python
# In your Django Socket.IO backend

await sio.emit('price_update', {
    'variant_id': 5,
    'new_price': 950.00,
    'old_price': 900.00,
    'discounted_price': None
}, room='product_variant_5')
```

Expected Flutter log:
```
[INFO] 🔥 Price Update Received: {...}
[INFO] ✅ Price update applied: PriceUpdateEvent(...)
```

### Test Inventory Update from Django

```python
await sio.emit('inventory_update', {
    'variant_id': 5,
    'current_quantity': 10,
    'previous_quantity': 22,
    'current_stock_unit': 'units',
    'warehouse_id': 1
}, room='product_variant_5')
```

Expected Flutter log:
```
[INFO] 📦 Inventory Update Received: {...}
[INFO] ✅ Inventory update applied: InventoryUpdateEvent(...)
```

---

## Common Issues & Solutions

### Issue 1: No Logs Appearing

**Symptom**: Nothing is printed to console

**Solutions**:
1. Make sure you're running in debug mode: `flutter run`
2. Check that App is converted to ConsumerWidget (check `app.dart`)
3. Verify `ref.watch(socketServiceProvider)` is in App's build method
4. Try `flutter clean && flutter pub get`

### Issue 2: Socket Connects but No Updates

**Symptom**: See "Socket.IO Connected" but no price updates

**Solutions**:
1. Check variant IDs match between API and Socket.IO (must be integer)
2. Verify product cards are calling `joinVariantRoom(variantId)`
3. Check backend is actually broadcasting to the correct room name: `product_variant_{id}`
4. Backend room name format: `room='product_variant_5'` for variant ID 5

### Issue 3: "Socket not connected" Warning

**Symptom**: See warning about socket not connected when joining rooms

**Solutions**:
1. Add a small delay before joining rooms:
   ```dart
   Future.delayed(const Duration(seconds: 1), () {
     socketService.joinVariantRoom(variantId);
   });
   ```
2. Or use the `onConnect` callback to join rooms after connection:
   ```dart
   socket.onConnect((_) {
     // Now join rooms
     socketService.joinVariantRoom(variantId);
   });
   ```

### Issue 4: Connection Fails (Connection Error)

**Symptom**: See "❌ Socket.IO Connection Error"

**Solutions**:
1. Verify backend URL is correct: `http://156.67.104.149:8080`
2. Backend must support WebSocket (check ASGI config)
3. Check firewall isn't blocking port 8080
4. Verify backend Socket.IO server is running
5. Try accessing from browser to verify connectivity:
   ```
   http://156.67.104.149:8080/socket.io/?EIO=4&transport=polling
   ```

### Issue 5: Updates Come but UI Doesn't Refresh

**Symptom**: Logs show updates but UI doesn't change

**Solutions**:
1. Make sure you're using `ConsumerWidget` or `ConsumerStatefulWidget`
2. Verify you're watching the notifier:
   ```dart
   final priceUpdates = ref.watch(priceUpdateNotifierProvider);
   ```
3. Check variant ID matches:
   ```dart
   final variantId = int.tryParse(product.variantId) ?? 0;
   final priceEvent = priceUpdates.getUpdate(variantId);
   ```
4. Ensure notifier is updating state correctly

---

## Enable More Verbose Logging

To see detailed Socket.IO logs, modify `socket_service.dart`:

```dart
// In socket_service.dart, add this to _setupConnectionListeners():

socket.onConnectError((error) {
  logger.e('❌ Connect Error Details: $error');
  logger.e('Type: ${error.runtimeType}');
});

socket.onError((error) {
  logger.e('⚠️ Socket Error Details: $error');
});
```

---

## Quick Checklist

- [ ] App.dart imports socket_provider
- [ ] App extends ConsumerWidget
- [ ] App.build watches socketServiceProvider
- [ ] Product cards extend ConsumerStatefulWidget
- [ ] Product cards call joinVariantRoom in initState
- [ ] Product cards watch priceUpdateNotifierProvider
- [ ] Product cards watch inventoryUpdateNotifierProvider
- [ ] Backend broadcasts to `product_variant_{variantId}` rooms
- [ ] Backend sends price_update with correct JSON structure
- [ ] Backend sends inventory_update with correct JSON structure
- [ ] Server is running on correct URL/port
- [ ] WebSocket is enabled on backend

---

## Expected Event Formats

### Price Update Event (from Django backend)

```json
{
  "variant_id": 5,
  "new_price": 900.0,
  "old_price": 1000.0,
  "discounted_price": 750.0
}
```

### Inventory Update Event (from Django backend)

```json
{
  "variant_id": 5,
  "current_quantity": 22,
  "previous_quantity": 25,
  "current_stock_unit": "units",
  "warehouse_id": 1
}
```

---

## Testing with Mock Data

If backend isn't ready, you can test with mock Socket.IO events:

```dart
// In a test screen
import 'package:grocery_app/core/network/socket_provider.dart';

class TestSocketScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socketService = ref.watch(socketServiceProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Simulate price update
          socketService.socket.emit('price_update', {
            'variant_id': 5,
            'new_price': 750.0,
            'old_price': 900.0,
          });
        },
        child: const Icon(Icons.shopping_bag),
      ),
    );
  }
}
```

Then when you tap the FAB, you should see the price update logs and UI should refresh.
