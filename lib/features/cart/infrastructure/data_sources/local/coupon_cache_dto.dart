import 'package:hive_ce/hive.dart';

/// Cache metadata for coupon list
/// Stores only Last-Modified and ETag headers for HTTP conditional requests
/// Does NOT cache the actual coupon list data (that stays in Riverpod state)
class CouponCacheDto extends HiveObject {
  CouponCacheDto({required this.lastSyncedAt, this.eTag, this.lastModified});

  /// When we last synced with server
  DateTime lastSyncedAt;

  /// ETag header from server response
  String? eTag;

  /// Last-Modified header from server response
  String? lastModified;

  CouponCacheDto copyWith({
    DateTime? lastSyncedAt,
    String? eTag,
    String? lastModified,
  }) {
    return CouponCacheDto(
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      eTag: eTag ?? this.eTag,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastSyncedAt': lastSyncedAt.toIso8601String(),
      'eTag': eTag,
      'lastModified': lastModified,
    };
  }

  factory CouponCacheDto.fromJson(Map<String, dynamic> json) {
    return CouponCacheDto(
      lastSyncedAt: DateTime.parse(json['lastSyncedAt'] as String),
      eTag: json['eTag'] as String?,
      lastModified: json['lastModified'] as String?,
    );
  }
}
