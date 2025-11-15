class Category {
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

  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? imagePath;
  final String? imageAlt;
  final int? parentId;
  final String? slug;
}
