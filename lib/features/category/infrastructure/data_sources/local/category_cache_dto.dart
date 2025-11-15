import '../../models/category_dto.dart';

class CategoryCacheDto {
  const CategoryCacheDto({
    required this.categories,
    required this.lastSyncedAt,
    this.eTag,
    this.lastModified,
    this.count,
    this.next,
    this.previous,
  });

  final List<CategoryDto> categories;
  final DateTime lastSyncedAt;
  final String? eTag;
  final String? lastModified;
  final int? count;
  final String? next;
  final String? previous;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'categories': categories.map((dto) => dto.toJson()).toList(),
    'lastSyncedAt': lastSyncedAt.toIso8601String(),
    if (eTag != null) 'eTag': eTag,
    if (lastModified != null) 'lastModified': lastModified,
    if (count != null) 'count': count,
    if (next != null) 'next': next,
    if (previous != null) 'previous': previous,
  };

  factory CategoryCacheDto.fromJson(Map<String, dynamic> json) {
    final categories = CategoryDto.listFromJson(json['categories']);
    final lastSyncedAtValue = json['lastSyncedAt'];
    if (lastSyncedAtValue is! String) {
      throw const FormatException('Invalid or missing `lastSyncedAt` value.');
    }

    return CategoryCacheDto(
      categories: categories,
      lastSyncedAt:
          DateTime.tryParse(lastSyncedAtValue)?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal(),
      eTag: json['eTag'] as String?,
      lastModified: json['lastModified'] as String?,
      count: json['count'] as int?,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
    );
  }
}
