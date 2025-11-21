/// Cache DTO for storing ONLY HTTP conditional request metadata
///
/// This stores ONLY:
/// - lastSyncedAt: When we last synced (used for TTL)
/// - lastModified: HTTP Last-Modified header (for If-Modified-Since)
/// - eTag: HTTP ETag header (for If-None-Match)
///
/// Product data is NOT cached here - only kept in Riverpod state (in-memory).
///
/// Why?
/// - Product data is in-memory while user is on page
/// - On navigate away/back: forceRefresh=true fetches fresh data
/// - Only metadata needed for conditional requests (bandwidth optimization)
///
/// Flow:
/// 1. First load: Fetch fresh data (200), save metadata to Hive
/// 2. Every 30s poll: Send If-Modified-Since with lastModified
///    - 304: No change, return null (UI doesn't refresh)
///    - 200: New data, update state + save metadata (UI refreshes)
/// 3. Navigate back: forceRefresh=true ignores cache, fetches fresh data
class ProductDetailCacheDto {
  ProductDetailCacheDto({
    required this.lastSyncedAt,
    this.eTag,
    this.lastModified,
  });

  final DateTime lastSyncedAt;
  final String? eTag;
  final String? lastModified;

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() => {
    'last_synced_at': lastSyncedAt.toIso8601String(),
    'etag': eTag,
    'last_modified': lastModified,
  };

  /// Create from JSON
  factory ProductDetailCacheDto.fromJson(Map<String, dynamic> json) {
    return ProductDetailCacheDto(
      lastSyncedAt: DateTime.parse(json['last_synced_at'] as String),
      eTag: json['etag'] as String?,
      lastModified: json['last_modified'] as String?,
    );
  }

  /// Copy with method for immutable updates
  ProductDetailCacheDto copyWith({
    DateTime? lastSyncedAt,
    String? eTag,
    String? lastModified,
  }) {
    return ProductDetailCacheDto(
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      eTag: eTag ?? this.eTag,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
