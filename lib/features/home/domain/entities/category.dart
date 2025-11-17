// features/home/domain/entities/category.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required String iconUrl,
  }) = _Category;

  // Custom factory to handle the actual API response structure
  factory Category.fromJson(Map<String, dynamic> json) {
    final rawIconUrl = json['background_image_url']?.toString() ?? '';
    String iconUrl = '';
    // Add https:// if the URL doesn't start with http:// or https://
    if (rawIconUrl.isNotEmpty && !rawIconUrl.startsWith('http')) {
      iconUrl = 'https://$rawIconUrl';
    } else {
      iconUrl = rawIconUrl;
    }

    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      iconUrl: iconUrl,
    );
  }
}
