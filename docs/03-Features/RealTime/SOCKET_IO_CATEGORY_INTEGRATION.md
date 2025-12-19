# Socket.IO Integration in Category Product Cards

## Overview

The product card component in the category screen now supports **real-time price and inventory updates** via Socket.IO.

## What Was Changed

### File: `_product_card.dart`

**Before**: `StatelessWidget` with static product data

**After**: `ConsumerStatefulWidget` with dynamic Socket.IO updates

### Key Features Added

✅ **Real-time Price Updates**
- Watches for price changes on Socket.IO
- Displays updated price immediately (with rupee symbol)
- Shows original price crossed out (if discount available)
- Falls back to API price if no Socket.IO update

✅ **Real-time Inventory Updates**
- Watches for stock level changes
- Shows stock status badge:
  - **Green "In Stock"** - when quantity > 10
  - **Orange "Only X left"** - when quantity < 10
  - **Red "Out of Stock"** - when quantity = 0
- Only shows badge when Socket.IO inventory update is available

✅ **Real-time Update Indicator**
- Blue sync icon appears in top-left corner of product image
- Indicates that data is being updated in real-time
- Helps users understand prices/stock are live

✅ **Automatic Room Management**
- Joins Socket.IO variant room on card mount
- Receives updates automatically
- No manual cleanup needed

## How It Works

```
API Response (Category Products)
         ↓
CategoryProductDto (contains variantId)
         ↓
ProductCard renders with variantId
         ↓
initState() → joinVariantRoom(variantId)
         ↓
Watches priceUpdateNotifierProvider & inventoryUpdateNotifierProvider
         ↓
When server sends price_update/inventory_update:
  - Riverpod notifiers update state
  - Widget rebuilds automatically
  - UI displays new price/stock
```

## Code Structure

### 1. State Management

```dart
class _ProductCardState extends ConsumerState<ProductCard> {
  late int variantId;

  @override
  void initState() {
    super.initState();
    variantId = int.tryParse(widget.product.variantId) ?? 0;

    if (variantId > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(socketServiceProvider).joinVariantRoom(variantId);
      });
    }
  }
```

### 2. Watching Real-Time Updates

```dart
// Watch price and inventory updates
final priceUpdates = ref.watch(priceUpdateNotifierProvider);
final inventoryUpdates = ref.watch(inventoryUpdateNotifierProvider);

// Get updates for this specific variant
final priceEvent = priceUpdates.getUpdate(variantId);
final inventoryEvent = inventoryUpdates.getUpdate(variantId);
```

### 3. Displaying Real-Time Data

```dart
// Use Socket.IO price if available, otherwise API price
final displayPrice = priceEvent?.newPrice != null
    ? priceEvent!.newPrice.toStringAsFixed(2)
    : widget.product.price;

// Use Socket.IO inventory if available
final inStock = (inventoryEvent?.currentQuantity ?? 0) > 0;
final quantity = inventoryEvent?.currentQuantity ?? 0;
```

## UI Indicators

### Price Update
- **Before**: `₹300`
- **After (with discount)**: `₹250` (old: `₹300`)
- **Indicator**: Blue sync icon in top-left of image

### Stock Status
- **High Stock**: Green badge "In Stock"
- **Low Stock**: Orange badge "Only 3 left"
- **Out of Stock**: Red badge "Out of Stock"
- **No Update**: No badge (uses API data)

## Data Flow

```
┌─────────────────────────────────────────┐
│   ProductCard (ConsumerStatefulWidget)   │
└─────────────────────────────────────────┘
              ↓
    initState() + joinVariantRoom()
              ↓
┌─────────────────────────────────────────┐
│   Socket.IO Room: product_variant_5     │
└─────────────────────────────────────────┘
              ↓
    Server sends: price_update event
              ↓
┌─────────────────────────────────────────┐
│   socket_provider (Riverpod Handler)    │
│   → PriceUpdateEvent.fromJson(data)     │
│   → priceUpdateNotifier.onPriceUpdate() │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  priceUpdateNotifierProvider (State)    │
│  state = {5: PriceUpdateEvent(...)}     │
└─────────────────────────────────────────┘
              ↓
    ref.watch() triggers rebuild
              ↓
   Display updated price on card
```

## Integration Points

### 1. Category Screen
The category screen doesn't need changes - it just renders ProductCard widgets as before.

### 2. Socket.IO Service
Uses existing socket service:
```dart
ref.read(socketServiceProvider).joinVariantRoom(variantId);
```

### 3. Riverpod State
Uses existing notifiers:
- `priceUpdateNotifierProvider`
- `inventoryUpdateNotifierProvider`

## Performance Considerations

✅ **Efficient Updates**
- Only rebuilds when data for that specific variant changes
- Uses variant ID to filter updates
- No unnecessary network calls

✅ **Memory Management**
- Rooms automatically managed per card
- Multiple cards for same variant reuse same Socket.IO room
- No memory leaks (Riverpod handles cleanup)

## Testing

### Manual Test

1. Open category screen
2. Watch console for:
   ```
   [INFO] 📍 Requested to join variant room: 5
   [INFO] ✅ Room Joined: {...}
   ```
3. Change price on backend
4. See price update on card in real-time
5. See stock badge change in real-time

### Backend Test Event

```python
# Django Socket.IO backend
await sio.emit('price_update', {
    'variant_id': 5,
    'new_price': 250.0,
    'old_price': 300.0,
    'discounted_price': None
}, room='product_variant_5')

await sio.emit('inventory_update', {
    'variant_id': 5,
    'current_quantity': 3,
    'previous_quantity': 10,
    'current_stock_unit': 'units',
    'warehouse_id': 1
}, room='product_variant_5')
```

## Comparison: Product Details Screen

The product card implementation mirrors the product details screen:
- Same Socket.IO integration pattern
- Same real-time update handling
- Same Riverpod state management
- Consistent user experience across app

## Files Modified

- `lib/features/category/presentation/components/widgets/_product_card.dart`
  - Changed from `StatelessWidget` to `ConsumerStatefulWidget`
  - Added Socket.IO room management
  - Added real-time price/inventory watching
  - Added visual indicators (sync icon, stock badge)

## No Breaking Changes

✅ Existing API still works as fallback
✅ No changes to parent components
✅ No changes to navigation
✅ Backward compatible with non-real-time scenarios

## Future Enhancements

1. **Wishlist Real-Time Updates**
   - Show when item is added to wishlist by other users
   - Update wishlist count in real-time

2. **Trending Products**
   - Show number of users viewing product
   - Update in real-time

3. **Flash Sales Indicator**
   - Show when product enters flash sale
   - Countdown timer

4. **User Reviews Live Updates**
   - Show new reviews as they come in
   - Update rating in real-time
