import 'package:equatable/equatable.dart';

/// Represents a product category in the grocery app.
///
/// This is a domain entity that represents the business concept of a category
/// without any infrastructure concerns like JSON serialization.
///
/// Two categories are equal if all their properties match. Use [copyWith]
/// to create modified copies for immutable updates.
///
/// Example:
/// ```dart
/// final produce = Category(
///   id: '1',
///   title: 'Produce',
///   imageUrl: 'https://example.com/produce.jpg',
/// );
///
/// // Create modified copy
/// final updatedProduce = produce.copyWith(title: 'Fresh Produce');
/// ```
class Category extends Equatable {
  /// Creates a new [Category] instance.
  const Category({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.imagePath,
    this.imageAlt,
    this.parentId,
    this.slug,
  });

  /// Unique identifier for the category (e.g., from backend API).
  final String id;

  /// Display name shown to users (e.g., "Produce", "Dairy", "Beverages").
  final String title;

  /// Optional detailed description of the category.
  final String? description;

  /// URL to the category image hosted on CDN.
  final String? imageUrl;

  /// Local file path if image is cached locally.
  final String? imagePath;

  /// Alt text for the category image (accessibility).
  final String? imageAlt;

  /// Parent category ID for hierarchical category structures (e.g., "Produce" as parent of "Vegetables").
  final int? parentId;

  /// URL-friendly slug for the category (e.g., "fresh-produce").
  final String? slug;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    imageUrl,
    imagePath,
    imageAlt,
    parentId,
    slug,
  ];

  /// Creates a copy of this category with specified fields replaced.
  ///
  /// Fields not provided will retain their current values.
  ///
  /// Example:
  /// ```dart
  /// final updated = category.copyWith(title: 'New Title');
  /// final multiple = category.copyWith(
  ///   title: 'New Title',
  ///   imageUrl: 'https://example.com/new.jpg',
  /// );
  /// ```
  Category copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? imagePath,
    String? imageAlt,
    int? parentId,
    String? slug,
  }) {
    return Category(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      imageAlt: imageAlt ?? this.imageAlt,
      parentId: parentId ?? this.parentId,
      slug: slug ?? this.slug,
    );
  }
}
