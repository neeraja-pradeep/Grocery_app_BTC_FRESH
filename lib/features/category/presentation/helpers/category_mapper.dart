import '../../application/states/category_state.dart';
import '../../domain/entities/category.dart';
import '../components/widgets/category_list.dart';

/// Maps domain entities to view models
class CategoryMapper {
  /// Converts Category entities to CategoryItem view models
  static List<CategoryItem> toViewItems(CategoryState state) {
    return state.categories
        .map((category) => _toCategoryItem(category))
        .toList(growable: false);
  }

  static CategoryItem _toCategoryItem(Category category) {
    final image = category.imageUrl ?? category.imagePath;
    final isLocalAsset = image != null && image.startsWith('assets/');

    return CategoryItem(
      id: category.id,
      title: category.title,
      assetPath: isLocalAsset ? image : null,
      imageUrl: !isLocalAsset ? image : null,
    );
  }
}
