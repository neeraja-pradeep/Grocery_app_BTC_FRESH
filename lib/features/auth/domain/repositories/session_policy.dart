/// Defines app startup decision modes for session loading
enum BootPolicy {
  /// Cold start, ignore any cached data
  coldNoCache,

  /// Cold start, load only from Hive (local storage)
  coldHiveOnly,

  /// Warm start, load from Hive and inject into Riverpod state
  warmHiveAndRiverpod,
}
