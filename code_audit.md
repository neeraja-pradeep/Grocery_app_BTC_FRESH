COMPREHENSIVE CODE AUDIT REPORT
Grocery App BTC FRESH - Feature/login/edwin Branch
🔴 CRITICAL ISSUES
1. EMPTY SECURE STORAGE IMPLEMENTATION
File: lib/core/storage/secure_store.dart:4-14
Severity: CRITICAL
Issue: SecureStore class has completely empty implementations - no actual secure storage is happening
Code:

class SecureStore {
  static Future<void> write(String key, String value) async {}
  static Future<String?> read(String key) async {
    return null;
  }
  static Future<void> delete(String key) async {}
  static Future<void> clear() async {}
}

Impact:

Any sensitive data (auth tokens, credentials) intended to be stored securely is NOT being stored at all
Complete security failure - data loss on app restart
Potential data exposure if this class is being used for sensitive information
App functionality will break if authentication depends on this
Fix Required:

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  static const _storage = FlutterSecureStorage();
  
  static Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  static Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }
  
  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
  
  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}

2. HARDCODED GOOGLE MAPS API KEY IN VERSION CONTROL
File: android/app/src/main/AndroidManifest.xml:52
Severity: CRITICAL
Issue: Google Maps API key is hardcoded and exposed in version control
Code:

<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyBuOyJfzRHyMJghiOPJlOQoiKi82XNxWyc"/>

Impact:

API key is exposed to anyone with repository access
Key can be extracted from APK by malicious actors
Unauthorized usage can lead to billing charges
Violates Google Cloud security best practices
Key rotation requires code changes and redeployment
Fix Required:

Revoke the exposed API key immediately
Move key to local.properties (not in version control):
# local.properties (add to .gitignore)
MAPS_API_KEY=your_new_api_key_here

Update build.gradle to read from local.properties:
def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

android {
    defaultConfig {
        manifestPlaceholders = [MAPS_API_KEY: localProperties.getProperty('MAPS_API_KEY', '')]
    }
}

Update AndroidManifest.xml:
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${MAPS_API_KEY}"/>

3. HIVE.OPENBOX() CALLED INSIDE REPOSITORY/DATA SOURCE METHODS
File: lib/features/home/infrastructure/data_sources/local/home_local_ds.dart:78
Severity: CRITICAL
Issue: Hive.openBox() is called inside data source getter method, violating initialization pattern
Code:

Future<Box> get box async {
  if (_box != null && _box!.isOpen) {
    return _box!;
  }
  if (Hive.isBoxOpen(HiveBoxes.homeBox)) {
    _box = Hive.box(HiveBoxes.homeBox);
    return _box!;
  }
  try {
    _box = await Hive.openBox(HiveBoxes.homeBox);  // ❌ CRITICAL
    return _box!;
  } catch (e) {
    throw StateError('Failed to open Hive box...');
  }
}

Impact:

Race conditions if multiple operations call this simultaneously
Unpredictable initialization order
Can cause app crashes if Hive.initFlutter() wasn't called
Performance degradation from repeated open attempts
Violates single responsibility principle
Fix Required:
All Hive boxes should be opened once during app initialization in app_bootstrap.dart, not lazily in data sources. Update data source to receive box instance:

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  final Box _box;
  
  HomeLocalDataSourceImpl(this._box);
  
  // Use _box directly, no lazy opening
}

// Provider
final homeLocalDataSourceProvider = Provider<HomeLocalDataSource>((ref) {
  return HomeLocalDataSourceImpl(Boxes.cacheBox);
});

Additional Files with Same Issue:

lib/features/cart/infrastructure/data_sources/local/coupon_local_data_source.dart:26
lib/features/cart/infrastructure/data_sources/local/address_local_data_source.dart:26
lib/features/cart/infrastructure/data_sources/remote/checkout_line_data_source.dart (needs verification)
4. REF.READ() IN ASYNC METHODS (_clearUserData, _refreshUserData)
File: lib/features/auth/application/providers/auth_provider.dart:229,256
Severity: CRITICAL
Issue: Using ref.read() to access providers inside async methods, which can cause stale data and rebuilds
Code:

Future<void> _clearUserData() async {
  try {
    final wishlistNotifier = ref.read(wishlistProvider.notifier);  // ❌
    await wishlistNotifier.clearCacheAndRefresh();

    final checkoutLineController = ref.read(
      checkoutLineControllerProvider.notifier,  // ❌
    );
    await checkoutLineController.refresh();
    // ... more ref.read calls
  } catch (e) {
    // ...
  }
}

Impact:

Can access disposed providers if auth state changes during async operation
Stale references lead to unpredictable behavior
Provider invalidation won't trigger updates
Memory leaks from unreleased provider references
Race conditions between logout and ongoing operations
Fix Required:
Move data clearing to separate providers that listen to auth state:

// In wishlist_provider.dart
@override
Widget build() {
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (next is GuestMode && previous is Authenticated) {
      clearCacheAndRefresh();
    }
  });
  // ...
}

Remove _clearUserData and _refreshUserData from auth_provider entirely. Each feature provider should manage its own auth state reactions.

5. HIVE.BOX() ACCESSED IN PROVIDER WITHOUT SAFETY CHECKS
File: lib/features/profile/application/providers/profile_provider.dart:14
Severity: CRITICAL
Issue: Hive.box() called directly in provider, can throw if box not opened
Code:

final profileLocalDsProvider = Provider<ProfileLocalDs>((ref) {
  final box = Hive.box<dynamic>(AppHiveBoxes.profile);  // ❌
  return ProfileLocalDs(box: box);
});

Impact:

App crashes if Hive boxes not initialized before provider access
Initialization order dependency issues
No error recovery mechanism
Provider creation fails permanently
Fix Required:

final profileLocalDsProvider = Provider<ProfileLocalDs>((ref) {
  // Use pre-opened box from Boxes singleton
  return ProfileLocalDs(box: Boxes.profileBox);
});

6. NO ASYNCVALUE.GUARD() IN ASYNC PROVIDERS
File: Across all providers (0 occurrences found)
Severity: CRITICAL
Issue: No providers use AsyncValue.guard() for error handling in async operations
Code:

// Example from orders_provider.dart:140-146
final orderDetailsProvider = FutureProvider.family<OrderEntity, String>((
  ref,
  orderId,
) async {
  final ordersApi = ref.watch(ordersApiProvider);
  return ordersApi.getOrderDetails(orderId);  // ❌ No error handling
});

Impact:

Unhandled exceptions crash the app
No graceful error states for users
Poor error messages
Cannot recover from network failures
AsyncValue remains in loading state forever on error
Fix Required:

final orderDetailsProvider = FutureProvider.family<OrderEntity, String>((
  ref,
  orderId,
) async {
  return AsyncValue.guard(() async {
    final ordersApi = ref.watch(ordersApiProvider);
    return ordersApi.getOrderDetails(orderId);
  });
});

7. LOGOUT NOT CLEARING HIVE BOXES
File: lib/features/auth/infrastructure/repositories/auth_repository_impl.dart:234
Severity: CRITICAL
Issue: Logout only clears cookies and calls Boxes.clearUserDataOnly(), but doesn't clear cacheBox which may contain sensitive data
Code:

@override
Future<void> logout() async {
  try {
    await local.clearAllUserData();
  } catch (e) {
    rethrow;
  }
}

// In auth_local_ds.dart:113
Future<void> clearAllUserData() async {
  await clearCookies();
  await Boxes.clearUserDataOnly();  // Only clears user, address, profile
}

// In boxes.dart:53
static Future<void> clearUserDataOnly() async {
  await userBox.clear();
  await addressBox.clear();
  await profileBox.clear();
  // ❌ cacheBox NOT cleared - may contain user data
}

Impact:

User B may see User A's cached data after logout
Privacy violation - previous user data remains accessible
Cached categories, products may show personalized data
Violates data protection requirements
Fails "user switching" test scenario
Fix Required:

static Future<void> clearUserDataOnly() async {
  await userBox.clear();
  await addressBox.clear();
  await profileBox.clear();
  await cacheBox.clear();  // ✅ Clear cache too
  await deliveryTrackingBox.clear();
}

8. LOGOUT NOT CALLING PROVIDER INVALIDATION
File: lib/features/auth/application/providers/auth_provider.dart:191-205
Severity: CRITICAL
Issue: Logout doesn't invalidate all user-specific providers, relies on manual clearing which may miss some providers
Code:

Future<void> logout() async {
  try {
    _otpExpiryTimer?.cancel();
    await _repository.logout();
    state = const GuestMode();
    
    await _clearUserData();  // Manual clearing, error-prone
  } catch (e) {
    state = const GuestMode();
    await _clearUserData();
    rethrow;
  }
}

Impact:

Some providers may retain authenticated user's data
Memory leaks from un-disposed providers
Stale data shown after logout
Race conditions between logout and provider access
Incomplete cleanup on logout failure
Fix Required:

Future<void> logout() async {
  try {
    _otpExpiryTimer?.cancel();
    await _repository.logout();
    
    // Invalidate all user-specific providers
    ref.invalidate(wishlistProvider);
    ref.invalidate(checkoutLineControllerProvider);
    ref.invalidate(categoryControllerProvider);
    ref.invalidate(profileControllerProvider);
    ref.invalidate(ordersProvider);
    // ... invalidate other user providers
    
    state = const GuestMode();
  } catch (e) {
    state = const GuestMode();
    rethrow;
  }
}

9. NO FIREBASE AUTH SIGN OUT IN LOGOUT FLOW
File: Throughout codebase (0 occurrences of FirebaseAuth found)
Severity: CRITICAL (if Firebase is used) / INFO (if not used)
Issue: No Firebase authentication sign out detected in logout flow
Code: N/A - Firebase not found in codebase
Impact:

If Firebase is used for any purpose, session may remain active
However, grep shows no FirebaseAuth imports, so this may not be applicable
Fix Required: If Firebase is added in future, ensure logout calls:

await FirebaseAuth.instance.signOut();

🟡 HIGH PRIORITY ISSUES
10. INCONSISTENT PROVIDER NAMING PATTERNS
File: Multiple provider files
Severity: HIGH
Issue: Provider naming doesn't consistently follow {feature}RepositoryProvider pattern
Examples:

lib/features/auth/application/providers/auth_repository_provider.dart ✅ Good
lib/features/wishlist/application/providers/wishlist_provider.dart (should be wishlistRepositoryProvider)
lib/features/orders/application/providers/orders_provider.dart (should be ordersRepositoryProvider)
Impact:

Code maintenance difficulty
Unclear provider purposes
Team confusion about architecture
Inconsistent codebase standards
Fix Required: Rename all providers to follow consistent pattern:

State notifier providers: {feature}Provider
Repository providers: {feature}RepositoryProvider
API providers: {feature}ApiProvider
11. MISSING AUTODISPOSE ON TEMPORARY UI STATE PROVIDERS
File: lib/features/wishlist/application/providers/wishlist_provider.dart:202-214
Severity: HIGH
Issue: Family providers marked autoDispose but state notifier provider is not
Code:

final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>(
  (ref) {  // ❌ Missing .autoDispose for keepAlive: false
    final repository = ref.watch(wishlistRepositoryProvider);
    return WishlistNotifier(repository: repository, ref: ref);
  },
);

// But selectors have autoDispose ✅
final wishlistItemsProvider = Provider.autoDispose<List<WishlistItem>>((ref) {
  final wishlistState = ref.watch(wishlistProvider);
  return wishlistState.items;
});

Impact:

Memory leaks - provider stays in memory when not needed
Unnecessary cache retention
Increased memory footprint
Family providers may be disposed while parent lives
Fix Required:
Audit all providers and add autoDispose for:

Temporary UI state (selected index, form fields, filters)
Screen-specific providers
Family providers with dynamic parameters
Keep global state (auth, app config) without autoDispose.

12. HIVE BOXES NOT DISPOSED IN AUTODISPOSE PROVIDERS
File: lib/core/storage/hive/boxes.dart:24-42
Severity: HIGH
Issue: Boxes are opened but closeHiveBoxes() is never called in app lifecycle
Code:

static Future<void> openHiveBoxes() async {
  userBox = await Hive.openBox(HiveKeys.userbox);
  addressBox = await Hive.openBox(HiveKeys.addressBox);
  // ...
}

static Future<void> closeHiveBoxes() async {
  await userBox.close();
  await addressBox.close();
  // ...
}

Impact:

Hive boxes remain open throughout app lifecycle
Potential data corruption on unexpected app termination
File handles not released properly
May cause issues on app reinstall
Fix Required:
Add app lifecycle management:

// In main.dart or app.dart
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      Boxes.closeHiveBoxes();
    }
  }
}

13. SYNCHRONOUS HIVE OPERATIONS ON POTENTIALLY LARGE DATASETS
File: lib/features/home/infrastructure/data_sources/local/home_local_ds.dart:122-142
Severity: HIGH
Issue: Saving large lists of products/categories synchronously without chunking
Code:

@override
Future<void> saveCategories(List<Category> categories) async {
  final b = await box;
  final jsonList = categories
      .map((category) => {
        'id': category.id,
        'name': category.name,
        // ... many fields
      })
      .toList();  // ❌ All at once, could be large
  
  await b.put(HiveKeys.homeCategories, _wrapJson(jsonList));
}

Impact:

UI freezes during large data saves
Poor UX on slower devices
Memory spikes from JSON serialization
ANR (Application Not Responding) on Android
Fix Required:
For large datasets, use:

Lazy box for large items
Batch operations
Compute isolate for JSON serialization
Future<void> saveCategories(List<Category> categories) async {
  final jsonList = await compute(_serializeCategories, categories);
  final b = await box;
  await b.put(HiveKeys.homeCategories, _wrapJson(jsonList));
}

static List<Map<String, dynamic>> _serializeCategories(List<Category> cats) {
  return cats.map((c) => {...}).toList();
}

14. ANDROID ALLOWBACKUP SETTING
File: android/app/src/main/AndroidManifest.xml:15
Severity: HIGH (Security Best Practice)
Issue: android:allowBackup="false" without backup rules
Code:

<application
    android:allowBackup="false"
    android:usesCleartextTraffic="true"
    ...>

Impact:

GOOD: Prevents auto-backup of sensitive data
CONCERN: usesCleartextTraffic="true" allows HTTP traffic (security risk)
Fix Required:

Remove usesCleartextTraffic="true" for production
If HTTP needed for debug, use network security config properly
15. REPOSITORIES CONTAINING BUSINESS LOGIC
File: lib/features/auth/infrastructure/repositories/auth_repository_impl.dart:29-42
Severity: HIGH
Issue: Repository validates session cookie and returns specific error messages (business logic)
Code:

Future<Either<Failure, UserEntity>> login({
  required String username,
  required String password,
}) async {
  try {
    final user = await remote.login(username: username, password: password);
    await local.saveUser(user);
    
    final session = await local.getValidSession(ApiClient.baseUrl);
    if (session == null) {  // ❌ Business logic in repository
      return const Left(AppFailure('No valid session cookie stored'));
    }
    
    return Right(user);
  } catch (e) {
    return Left(mapDioError(e));
  }
}

Impact:

Violates clean architecture separation
Business logic scattered across layers
Difficult to test business rules
Hard to modify validation logic
Fix Required:
Move validation to use case layer:

// Repository just fetches/saves
Future<Either<Failure, UserEntity>> login(...) async {
  final user = await remote.login(...);
  await local.saveUser(user);
  return Right(user);
}

// Use case validates
class LoginUseCase {
  Future<Either<Failure, UserEntity>> execute(...) async {
    final result = await repository.login(...);
    return result.flatMap((user) {
      final session = local.getValidSession(...);
      if (session == null) {
        return Left(AppFailure('No valid session'));
      }
      return Right(user);
    });
  }
}

16. MISSING TYPE ADAPTER REGISTRATIONS CHECK
File: lib/app/bootstrap/hive_init.dart (need to verify)
Severity: HIGH
Issue: Need to verify all TypeAdapters registered before box access
Impact:

App crashes if adapter not registered
Data corruption from wrong adapter versions
Fix Required: Verify in HiveInit that all adapters are registered:

// Should have:
Hive.registerAdapter(UserModelAdapter());
Hive.registerAdapter(AddressModelAdapter());
Hive.registerAdapter(DeliveryTrackingAdapter());

17. PRINT STATEMENTS IN PRODUCTION CODE
File: Multiple files (21 occurrences across 6 files)
Severity: HIGH
Issue: print() statements found in production code instead of proper logging
Files with print statements:

lib/core/services/voice_search_service.dart:2
lib/features/wishlist/infrastructure/data_sources/wishlist_api.dart:1
lib/features/wishlist/domain/entities/wishlist_item.dart:7
lib/features/category/domain/repositories/category_repository.dart:2
lib/features/home/application/providers/search_history_provider_simple.dart:1
lib/features/home/application/providers/search_history_provider.dart:8
Impact:

Sensitive data potentially logged
Performance overhead in production
Logs not structured or filterable
Cannot disable in release builds
Potential information disclosure
Fix Required:
Replace all print statements with proper logger:

import 'package:logger/logger.dart';

final logger = Logger();

// Instead of: print('User logged in: $userId');
logger.i('User logged in', userId);  // No sensitive data in logs

18. NETWORK ERROR HANDLING WITHOUT RETRY LOGIC
File: Multiple providers
Severity: HIGH
Issue: Critical operations like login, checkout don't have retry logic
Impact:

Poor UX on temporary network issues
Failed operations on flaky connections
Users must manually retry
Fix Required:
Implement retry logic for critical operations:

Future<T> withRetry<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
  for (var i = 0; i < maxRetries; i++) {
    try {
      return await operation();
    } catch (e) {
      if (i == maxRetries - 1 || !isRetryableError(e)) rethrow;
      await Future.delayed(Duration(seconds: 2 << i));
    }
  }
  throw Exception('Max retries exceeded');
}

🟠 MEDIUM PRIORITY ISSUES
19. EXCESSIVE PRINT STATEMENTS NEED CLEANUP
File: 6 files with 21 total print occurrences
Severity: MEDIUM
Issue: While not critical, print statements should be replaced with proper logging framework
Impact: Covered in HIGH PRIORITY #17

20. MAGIC NUMBERS IN CODE
File: lib/features/auth/application/providers/auth_provider.dart:80,178
Severity: MEDIUM
Issue: Hardcoded 300 seconds for OTP expiry
Code:

state = OtpSent(
  mobileNumber: mobileNumber,
  isSuccess: isSuccess,
  expiresInSeconds: 300,  // ❌ Magic number
);

_otpExpiryTimer = Timer(const Duration(seconds: 300), () {  // ❌ Magic number

Impact:

Difficult to change expiry time
Inconsistency if values differ
No single source of truth
Fix Required:

class AuthConfig {
  static const otpExpirySeconds = 300;
  static const otpExpiryDuration = Duration(seconds: otpExpirySeconds);
}

// Usage:
expiresInSeconds: AuthConfig.otpExpirySeconds,
Timer(AuthConfig.otpExpiryDuration, () {

21. MISSING DOCUMENTATION ON COMPLEX PROVIDERS
File: Multiple provider files
Severity: MEDIUM
Issue: Complex providers like checkout_line_provider have minimal documentation
Impact:

Difficult for new developers to understand
Maintenance complexity
Unclear business logic
Fix Required:
Add comprehensive documentation:

/// Checkout lines controller - manages cart state with page-focused polling
///
/// ARCHITECTURE:
/// - Uses 30-second polling when Cart screen is active
/// - Stops polling when user navigates away
/// - Implements debouncing for quantity updates (150ms)
///
/// STATE MANAGEMENT:
/// - Optimistic UI updates for better UX
/// - Rollback on API errors
/// - Processing state prevents race conditions
///
/// POLLING:
/// - Registered with PollingManager for lifecycle management
/// - Only polls when 'cart' feature is active (see PollingTabController)
/// - Uses conditional headers (If-None-Match) for bandwidth optimization
class CheckoutLineController extends Notifier<CheckoutLineState> {

22. TODO/FIXME IN PRODUCTION CODE
File: lib/features/address/presentation/screens/address_form_screen.dart
Severity: MEDIUM
Issue: 1 TODO found in code
Impact:

Incomplete implementation
Technical debt
May cause issues if TODO is critical
Fix Required:
Review and complete or remove all TODOs before deployment.

23. UNUSED IMPORTS
File: To be verified with flutter analyze
Severity: MEDIUM
Issue: Cannot run flutter analyze (command not found in environment)
Impact:

Code bloat
Confusion about dependencies
Slower compilation
Fix Required:
Run dart fix --apply to auto-remove unused imports.

24. VERSION NUMBER NOT MANAGED PROPERLY
File: pubspec.yaml:5
Severity: MEDIUM
Issue: Version is 1.0.0+1, should be incremented for release
Code:

version: 1.0.0+1

Impact:

App store update issues
Cannot track deployed versions
User confusion about app version
Fix Required:
Increment version before each release:

version: 1.0.1+2  # version_name+build_number

25. CHANGELOG.MD NOT FOUND
File: Root directory
Severity: MEDIUM
Issue: No CHANGELOG.md file to track changes
Impact:

Difficult to track feature history
QA cannot verify changes
Users don't know what's new
Fix Required:
Create CHANGELOG.md following keepachangelog.com format.

26. DUPLICATE HIVE PACKAGES
File: pubspec.yaml:42-43,66-67
Severity: MEDIUM
Issue: Both hive_flutter AND hive_ce packages are included
Code:

dependencies:
  hive_flutter: ^1.1.0
  hive: ^2.2.3
  hive_ce: ^2.15.1
  hive_ce_flutter: ^2.3.3

dev_dependencies:
  hive_ce_generator: ^1.9.2

Impact:

Conflicting implementations
Larger APK size
Potential runtime conflicts
Unclear which version to use
Fix Required:
Choose one Hive version and remove the other:

dependencies:
  # Use hive_ce packages (newer, community edition)
  hive_ce: ^2.15.1
  hive_ce_flutter: ^2.3.3

dev_dependencies:
  hive_ce_generator: ^1.9.2

Remove: hive_flutter, hive

27. DEPENDENCY VERSION CONSTRAINTS
File: pubspec.yaml:28
Severity: MEDIUM
Issue: fluttertoast has no version specified
Code:

fluttertoast:  # ❌ No version constraint
Impact:

Unpredictable builds
Dependency conflicts
Breaking changes on pub get
Fix Required:

fluttertoast: ^8.2.2  # ✅ Specific version

28. USESCLEARTEXTTRAFFIC ENABLED
File: android/app/src/main/AndroidManifest.xml:16
Severity: MEDIUM
Issue: Clear text (HTTP) traffic allowed
Code:

android:usesCleartextTraffic="true"

Impact:

Security risk - allows unencrypted HTTP
App store may reject for security reasons
Man-in-the-middle attack vulnerability
Fix Required:
Remove for production or use only for debug builds:

<!-- Remove for production -->
android:usesCleartextTraffic="false"

29. APK SIZE OPTIMIZATION NOT VERIFIED
File: android/app/build.gradle (not read)
Severity: MEDIUM
Issue: Need to verify if APK splitting and shrinking are enabled
Fix Required:
Verify build.gradle has:

android {
    buildTypes {
        release {
            shrinkResources true
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
    
    splits {
        abi {
            enable true
            reset()
            include 'armeabi-v7a', 'arm64-v8a'
            universalApk false
        }
    }
}

30. MISSING MIGRATION LOGIC FOR DATA FORMAT CHANGES
File: N/A
Severity: MEDIUM
Issue: No versioning or migration strategy for Hive box schema changes
Impact:

App crashes after updates if data format changes
User data loss
Requires uninstall/reinstall
Fix Required:
Implement version checking:

class HiveInit {
  static const currentVersion = 2;
  
  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getInt('hive_version') ?? 1;
    
    if (savedVersion < currentVersion) {
      await _migrateData(from: savedVersion, to: currentVersion);
      await prefs.setInt('hive_version', currentVersion);
    }
    
    // Register adapters and open boxes
  }
  
  static Future<void> _migrateData({required int from, required int to}) async {
    // Handle migration logic
  }
}

