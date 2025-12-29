# Address Flow - Complete Documentation

## Overview

The Address Flow manages delivery addresses throughout the app. Users can add, edit, delete, and select addresses from multiple screens (Address List Screen, Cart Bottom Sheet). The system handles synchronization across multiple providers and includes a workaround for a backend bug.

---

## Architecture

### Files Involved

```
lib/
├── features/
│   ├── address/
│   │   ├── application/
│   │   │   ├── providers/
│   │   │   │   └── address_provider.dart       # Profile address state (String IDs)
│   │   │   └── states/
│   │   │       └── address_state.dart          # Address state with local selection
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── address.dart                # Address entity
│   │   ├── infrastructure/
│   │   │   └── data_sources/
│   │   │       └── address_api.dart            # API calls
│   │   └── presentation/
│   │       └── screens/
│   │           └── address_list_screen.dart    # Full address list UI
│   ├── cart/
│   │   ├── application/
│   │   │   └── providers/
│   │   │       └── address_providers.dart      # Cart address state (int IDs)
│   │   └── presentation/
│   │       └── components/
│   │           └── address_sheet.dart          # Bottom sheet for address selection
│   ├── auth/
│   │   └── presentation/
│   │       └── screen/
│   │           └── address_screen.dart         # Add/Edit address form
│   └── home/
│       └── application/
│           └── providers/
│               └── home_provider.dart          # Home screen address display
```

---

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            ADDRESS FLOW                                      │
└─────────────────────────────────────────────────────────────────────────────┘

                    ┌──────────────────────────┐
                    │       Entry Points       │
                    └──────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ Profile Menu  │    │ Cart Screen   │    │ Checkout      │
│ "My Addresses"│    │ Address Bar   │    │ "Change"      │
└───────┬───────┘    └───────┬───────┘    └───────┬───────┘
        │                    │                    │
        ▼                    └────────┬───────────┘
┌───────────────────┐                 │
│ AddressListScreen │                 ▼
│                   │        ┌───────────────────┐
│ • View all        │        │   AddressSheet    │
│ • Select address  │        │   (Bottom Sheet)  │
│ • Edit/Delete     │        │                   │
│ • Add new         │        │ • View all        │
└───────┬───────────┘        │ • Select address  │
        │                    │ • Edit/Delete     │
        │                    │ • Add new         │
        │                    └───────┬───────────┘
        │                            │
        └────────────┬───────────────┘
                     │
                     ▼
        ┌───────────────────────────────────────┐
        │           User Actions                │
        └───────────────────────────────────────┘
                     │
    ┌────────────────┼────────────────┬─────────────────┐
    │                │                │                 │
    ▼                ▼                ▼                 ▼
┌────────┐    ┌───────────┐    ┌───────────┐    ┌───────────┐
│  ADD   │    │  SELECT   │    │   EDIT    │    │  DELETE   │
└────┬───┘    └─────┬─────┘    └─────┬─────┘    └─────┬─────┘
     │              │                │                │
     ▼              ▼                ▼                ▼
┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────────┐
│AddressScreen│ │PATCH API  │ │AddressScreen│ │Confirm Dialog │
│(Empty form)│ │/address/id/│ │(Pre-filled)│ │"Are you sure?" │
└─────┬──────┘ └─────┬──────┘ └─────┬──────┘ └───────┬────────┘
      │              │              │                │
      ▼              ▼              ▼                ▼
┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────────┐
│POST API    │ │Sync All    │ │PATCH API   │ │DELETE API      │
│/address/   │ │Providers   │ │/address/id/│ │/address/id/    │
└─────┬──────┘ └─────┬──────┘ └─────┬──────┘ └───────┬────────┘
      │              │              │                │
      └──────────────┴──────────────┴────────────────┘
                              │
                              ▼
                 ┌───────────────────────┐
                 │  Refresh All Screens  │
                 │  • Home (top bar)     │
                 │  • Address List       │
                 │  • Cart Bottom Sheet  │
                 └───────────────────────┘
```

---

## API Endpoints

### 1. Get All Addresses

**Endpoint:**
```
GET /api/auth/v1/address/
```

**Response:**
```json
{
  "count": 2,
  "results": [
    {
      "id": 46,
      "first_name": "John",
      "last_name": "Doe",
      "street_address_1": "123 Main St",
      "street_address_2": "Apt 4B",
      "city": "Mumbai",
      "city_area": "Andheri",
      "postal_code": "400001",
      "country": "IN",
      "latitude": "19.1234",
      "longitude": "72.5678",
      "address_type": "HOME",
      "selected": true
    }
  ]
}
```

### 2. Get Selected Address

**Endpoint:**
```
GET /api/auth/v1/address/?selected=true
```

**Response:**
```json
{
  "count": 1,
  "results": [
    {
      "id": 46,
      "selected": true,
      ...
    }
  ]
}
```

> **Backend Bug:** This endpoint may return stale data after selecting a new address. See "Backend Bug Workaround" section.

### 3. Create Address

**Endpoint:**
```
POST /api/auth/v1/address/
```

**Request:**
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "street_address_1": "123 Main St",
  "street_address_2": "Apt 4B",
  "city": "Mumbai",
  "city_area": "Andheri",
  "postal_code": "400001",
  "country": "IN",
  "latitude": 19.1234,
  "longitude": 72.5678,
  "address_type": "HOME"
}
```

### 4. Update Address

**Endpoint:**
```
PATCH /api/auth/v1/address/{id}/
```

**Request:**
```json
{
  "street_address_1": "456 New St",
  "city": "Delhi"
}
```

### 5. Select Address

**Endpoint:**
```
PATCH /api/auth/v1/address/{id}/
```

**Request:**
```json
{
  "selected": true
}
```

**Response:** Returns the updated address with `selected: true`

> **Note:** Backend should set `selected: false` on all other addresses, but this may not always work correctly.

### 6. Delete Address

**Endpoint:**
```
DELETE /api/auth/v1/address/{id}/
```

**Response:** `204 No Content`

---

## State Management

### Multiple Providers

The app uses two separate address providers due to different ID types and contexts:

| Provider | Location | ID Type | Used By |
|----------|----------|---------|---------|
| `profileAddressControllerProvider` | `address_provider.dart` | `String` | Address List Screen, Profile |
| `addressControllerProvider` | `cart/address_providers.dart` | `int` | Cart, Checkout, Bottom Sheet |

### Profile Address State

```dart
// address_state.dart
class AddressState {
  final List<Address> addresses;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final String? localSelectedAddressId;  // Workaround for backend bug

  Address? get selectedAddress {
    // Priority: local selection > API selection
    if (localSelectedAddressId != null) {
      return addresses.firstWhereOrNull(
        (addr) => addr.id == localSelectedAddressId,
      );
    }
    return addresses.firstWhereOrNull((addr) => addr.selected);
  }
}
```

### Cart Address State

```dart
// cart/address_providers.dart
class AddressState {
  final AddressStatus status;
  final AddressList? addressList;
  final bool isRefreshing;
  final DateTime? lastSyncedAt;
}
```

---

## Backend Bug Workaround

### The Problem

After selecting an address via `PATCH /address/{id}/ {"selected": true}`:
1. The PATCH response correctly shows the new address as selected
2. But `GET /address/?selected=true` still returns the OLD selected address
3. This causes the UI to show wrong address after refresh

### The Solution: Local Selection Tracking

```dart
// In AddressState
final String? localSelectedAddressId;

// In AddressProvider
void setLocalSelectedAddressId(String id) {
  // Update local state immediately
  final updatedAddresses = state.addresses.map((addr) {
    return Address(
      id: addr.id,
      // ... copy all fields
      selected: addr.id == id,  // Override selection
    );
  }).toList();

  state = state.copyWith(
    addresses: updatedAddresses,
    localSelectedAddressId: id,
  );
}

// When fetching/refreshing, apply local selection override
Future<void> fetchAddresses() async {
  final addresses = await _api.fetchAddresses();

  // Apply local selection override if exists
  if (state.localSelectedAddressId != null) {
    addresses = addresses.map((addr) => addr.copyWith(
      selected: addr.id == state.localSelectedAddressId,
    )).toList();
  }

  state = state.copyWith(addresses: addresses);
}
```

---

## Cross-Provider Synchronization

When an address is selected from one screen, all providers must be updated:

### From Address List Screen

```dart
// address_list_screen.dart
Future<void> _selectAddress(Address address) async {
  // 1. Update profile provider (primary)
  await ref.read(profileAddressControllerProvider.notifier)
      .selectAddress(address.id);

  // 2. Sync with cart provider
  final addressId = int.tryParse(address.id);
  if (addressId != null) {
    ref.read(addressControllerProvider.notifier).selectAddress(addressId);
  }
}
```

### From Bottom Sheet

```dart
// address_sheet.dart
Future<void> _onAddressSelected(AddressEntity address) async {
  // 1. Update cart provider (primary)
  await ref.read(addressControllerProvider.notifier)
      .selectAddress(address.id);

  // 2. Convert to UserAddress for home screen
  final userAddress = UserAddress(
    id: address.id,
    streetAddress1: address.streetAddress1,
    // ... other fields
  );

  // 3. Update home screen
  ref.read(homeProvider.notifier).updateAddressInState(userAddress);

  // 4. Update profile provider's local selection
  ref.read(profileAddressControllerProvider.notifier)
      .setLocalSelectedAddressId(address.id.toString());

  // 5. Close bottom sheet
  Navigator.pop(context);
}
```

---

## Delete Flow

### From Address List Screen

```dart
Future<void> _deleteAddress(Address address) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Address'),
      content: Text('Are you sure?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
      ],
    ),
  );

  if (confirmed == true) {
    await ref.read(profileAddressControllerProvider.notifier)
        .deleteAddress(address.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Address deleted')),
    );
  }
}
```

### From Bottom Sheet

```dart
Future<void> _handleDelete(BuildContext context, int id) async {
  final confirmed = await showDialog<bool>(...);

  if (confirmed == true && context.mounted) {
    // 1. Delete via cart provider
    await ref.read(addressControllerProvider.notifier).deleteAddress(id);

    // 2. Refresh profile provider (sync)
    ref.read(profileAddressControllerProvider.notifier).fetchAddresses();

    // 3. Show success message
    ScaffoldMessenger.of(context).showSnackBar(...);

    // 4. Close bottom sheet
    Navigator.pop(context);
  }
}
```

---

## Polling & Refresh

### Screen-Aware Polling

Address polling only runs when user is on Cart tab:

```dart
// address_providers.dart
void _startPolling() {
  // Register with PollingManager - DO NOT start timer here
  PollingManager.instance.registerPoller(
    featureName: 'cart',
    resourceId: 'addresses',
    onResume: _resumePolling,   // Called when Cart tab active
    onPause: _pausePolling,     // Called when user leaves Cart
  );
}

void _resumePolling() {
  _startPollingTimer();  // Actually starts 30-second timer
}

void _pausePolling() {
  _pollingTimer?.cancel();
  _pollingTimer = null;
}
```

### Force Refresh After Mutations

After create/update/delete, use force refresh to bypass 304:

```dart
Future<void> deleteAddress(int id) async {
  await _repository.deleteAddress(id);

  // Force refresh bypasses conditional request (304)
  await _forceRefresh();
}

Future<void> _forceRefresh() async {
  final addressList = await _repository.getAddressList(forceRefresh: true);
  state = state.copyWith(addressList: addressList);
}
```

---

## UI Components

### Address List Screen

- Full-screen list of all addresses
- Radio button for selection
- PopupMenuButton for Edit/Delete
- FloatingActionButton to add new
- Pull-to-refresh support

### Address Bottom Sheet

- Modal bottom sheet from Cart/Checkout
- Compact address cards
- Tap to select
- PopupMenuButton for Edit/Delete
- "Add New Address" button

### Address Form (AddressScreen)

- Text fields for all address components
- Google Maps integration for location
- Address type selector (Home/Work/Other)
- Save button with validation

---

## Entity Conversion

Different providers use different Address types:

```dart
// Cart's AddressEntity (int id)
class AddressEntity {
  final int id;
  final String streetAddress1;
  ...
}

// Profile's Address (String id)
class Address {
  final String id;
  final String streetAddress1;
  ...
}

// Home's UserAddress
class UserAddress {
  final int id;
  final String streetAddress1;
  ...
}

// Conversion when syncing
final userAddress = UserAddress(
  id: addressEntity.id,
  streetAddress1: addressEntity.streetAddress1,
  city: addressEntity.city,
  ...
);
```

---

## Error Handling

```dart
try {
  await ref.read(addressControllerProvider.notifier).deleteAddress(id);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Address deleted'), backgroundColor: Colors.green),
  );
} catch (error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed to delete: $error'), backgroundColor: Colors.red),
  );
}
```

---

## Related Documentation

- [Payment Flow](../../payment_flow.md) - Uses selected address for delivery
- [Cart Flow](../Cart/CART_FLOW.md) - Address selection in checkout
- [Screen-Aware Polling](../../02-Architecture/Performance/SCREEN_AWARE_POLLING_GUIDE.md)

---

**Last Updated:** 2025-12-25
