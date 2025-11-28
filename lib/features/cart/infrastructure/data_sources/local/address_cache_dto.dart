import 'package:hive/hive.dart';

/// Cache metadata for address list
/// Stores only Last-Modified and ETag headers for HTTP conditional requests
/// Does NOT cache the actual address list data (that stays in Riverpod state)
class AddressCacheDto extends HiveObject {
  AddressCacheDto({required this.lastSyncedAt, this.eTag, this.lastModified});

  /// When we last synced with server
  DateTime lastSyncedAt;

  /// ETag header from server response
  String? eTag;

  /// Last-Modified header from server response
  String? lastModified;

  AddressCacheDto copyWith({
    DateTime? lastSyncedAt,
    String? eTag,
    String? lastModified,
  }) {
    return AddressCacheDto(
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

  factory AddressCacheDto.fromJson(Map<String, dynamic> json) {
    return AddressCacheDto(
      lastSyncedAt: DateTime.parse(json['lastSyncedAt'] as String),
      eTag: json['eTag'] as String?,
      lastModified: json['lastModified'] as String?,
    );
  }
}
