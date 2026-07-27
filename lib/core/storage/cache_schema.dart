/// Schema versions for cached payloads.
///
/// Bump a version when previously-written cache entries are *incomplete or
/// wrong* by the new code's standards — not merely when fields are added.
/// Repositories compare the stored version against the current one and, when
/// it is older, refetch in full (dropping the ETag / If-Modified-Since
/// validators) so the stale entry is replaced rather than revalidated.
///
/// Without this, an upgrade could pin bad data in place forever: the cached
/// body is wrong but its validators are still valid, so the server keeps
/// answering 304 and the client keeps serving the bad body.
class CacheSchema {
  const CacheSchema._();

  /// Category list cache.
  ///
  /// v1 — first page only (25 of 40 categories); the paginated `next` link was
  ///      never followed.
  /// v2 — every page followed, so the entry holds the complete list.
  static const int categoryList = 2;

  /// Category products cache.
  ///
  /// v1 — first page only, so any category with more than 25 products was
  ///      silently truncated.
  /// v2 — every page followed.
  static const int categoryProducts = 2;

  /// Version assumed for an entry written before versioning existed.
  static const int legacy = 1;
}
