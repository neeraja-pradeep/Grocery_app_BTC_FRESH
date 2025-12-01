# Design Document

## Overview

This design integrates the existing home screen components with a robust data flow architecture using Riverpod state management, proper caching with Hive, and intelligent loading strategies. The solution addresses the current issues in the codebase where cache logic is commented out and providers don't properly handle the cache-first approach.

## Architecture

### Data Flow Architecture

```
UI Layer (Widgets)
    ↓
Application Layer (Riverpod Providers & Controllers)
    ↓
Domain Layer (Repository Interface)
    ↓
Infrastructure Layer (Repository Implementation)
    ↓
Data Sources (Remote API + Local Cache)
```

### Loading Strategy

The system implements a three-path loading strategy:

1. **Instant UI Path**: Riverpod state exists → Show immediately → Background refresh
2. **Cache Hydration Path**: Cache exists, Riverpod empty → Load from cache → Show UI → Background refresh  
3. **Cold Start Path**: No cache, no state → Show loading → Fetch from API → Cache → Show UI

## Components and Interfaces

### State Management Layer

#### HomeBootstrapState
```dart
class HomeBootstrapState {
  final bool isInitialLoading;
  final String? error;
  final bool isBootComplete;
}
```

#### CatalogState (Enhanced)
```dart
class CatalogState {
  final List<Category> categories;
  final List<Product> bestDeals;
  final List<Offer> megaOffers;
  final bool isRefreshing;
  final String? error;
  final DateTime? lastUpdated;
  final bool hasData;
}
```

### Provider Architecture

#### Core Providers
- `homeBootstrapControllerProvider`: Manages initial loading state
- `catalogControllerProvider`: Manages home screen data state
- `homeRepositoryProvider`: Repository dependency injection
- `homeCacheServiceProvider`: Local storage service

#### Data Providers (Refactored)
- `categoriesProvider`: Smart cache-first categories loading
- `bestDealsProvider`: Smart cache-first best deals loading  
- `megaOffersProvider`: Smart cache-first mega offers loading

### Repository Layer Enhancement

#### HomeRepository Interface (No Changes)
The existing interface is well-designed and doesn't need modifications.

#### HomeRepositoryImpl (Enhanced)
- Replace in-memory cache with proper Hive implementation
- Add connectivity checking
- Implement proper error handling with custom exceptions
- Add cache expiration logic

### Cache Service Layer

#### HomeCacheService
```dart
abstract class HomeCacheService {
  Future<void> saveCategories(List<Category> categories);
  Future<List<Category>?> getCategories();
  Future<void> saveBestDeals(List<Product> products);
  Future<List<Product>?> getBestDeals();
  Future<void> saveMegaOffers(List<Offer> offers);
  Future<List<Offer>?> getMegaOffers();
  Future<void> saveLastUpdated(String key, DateTime timestamp);
  Future<DateTime?> getLastUpdated(String key);
  Future<bool> isCacheExpired(String key, Duration maxAge);
}
```

## Data Models

### Cache Models
All existing entity models (Category, Product, Offer) need:
- `toJson()` and `fromJson()` methods for Hive serialization
- Proper equality and hashCode implementations

### Error Handling Models
```dart
abstract class HomeFailure {
  final String message;
}

class NetworkFailure extends HomeFailure {
  NetworkFailure(String message) : super(message);
}

class CacheFailure extends HomeFailure {
  CacheFailure(String message) : super(message);
}
```

## Error Handling

### Error Strategy
1. **Network + Cache Available**: Show cached data, display error toast
2. **Network + No Cache**: Show error state with retry button
3. **Offline + Cache Available**: Show cached data with offline indicator
4. **Offline + No Cache**: Show offline message with retry when online

### Error Recovery
- Automatic retry with exponential backoff
- Manual retry through UI actions
- Graceful degradation to cached content

## Testing Strategy

### Unit Tests
- Repository implementation with mocked data sources
- Cache service with mocked Hive boxes
- Provider logic with mocked dependencies
- Error handling scenarios

### Integration Tests  
- End-to-end data flow from API to UI
- Cache persistence across app restarts
- Offline/online state transitions
- Pull-to-refresh functionality

### Widget Tests
- Home screen loading states
- Error state displays
- Pull-to-refresh interactions
- Data display correctness

## Implementation Notes

### Current Issues to Fix
1. **Commented Cache Logic**: The current providers have cache checks commented out
2. **Missing State Controllers**: Need proper StateNotifier controllers for complex state management
3. **No Hive Integration**: Currently using in-memory cache instead of persistent storage
4. **Missing Error Handling**: No proper error states or recovery mechanisms
5. **No Loading States**: Missing proper loading indicators for different scenarios

### Key Improvements
1. **Smart Caching**: Implement cache-first strategy with background refresh
2. **Proper State Management**: Use StateNotifier for complex state with multiple properties
3. **Error Resilience**: Comprehensive error handling with user-friendly messages
4. **Performance**: Minimize unnecessary API calls through intelligent caching
5. **Offline Support**: Full offline functionality with cached data