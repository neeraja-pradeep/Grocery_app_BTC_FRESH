class AppHiveBoxes {
  const AppHiveBoxes._();

  // Profile module boxes (from dev)
  static const String cache = 'app_cache_box';
  static const String profile = 'profile_box';
  static const String address = 'address_box';

  // Home/Wishlist module boxes (from feature)
  static const String homeBox = 'homeBox';
  static const String catalogBox = 'catalogBox';
  static const String userPrefsBox = 'userPrefsBox';
}

// Alias for backward compatibility with feature branch code
typedef HiveBoxes = AppHiveBoxes;
