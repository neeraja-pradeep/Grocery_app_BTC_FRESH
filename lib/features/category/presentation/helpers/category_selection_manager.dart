import '../../domain/entities/category.dart';

/// Manages category selection state and synchronization logic
class CategorySelectionManager {
  int selectedIndex;
  String? selectedCategoryId;

  CategorySelectionManager({this.selectedIndex = 0, this.selectedCategoryId});

  /// Updates selection based on new category list
  /// Returns true if selection changed
  bool updateSelection({
    required List<Category> previousCategories,
    required List<Category> nextCategories,
  }) {
    if (nextCategories.isEmpty) {
      return _resetSelection();
    }

    final currentSelectedId = _resolveCurrentSelectedId(
      previousCategories: previousCategories,
      nextCategories: nextCategories,
    );

    final resolvedIndex = nextCategories.indexWhere(
      (c) => c.id == currentSelectedId,
    );
    final targetIndex = resolvedIndex >= 0 ? resolvedIndex : 0;
    final targetId = nextCategories[targetIndex].id;

    if (selectedIndex != targetIndex || selectedCategoryId != targetId) {
      selectedIndex = targetIndex;
      selectedCategoryId = targetId;
      return true;
    }

    return false;
  }

  /// Manually select a category by index
  void selectCategory(int index, String? categoryId) {
    selectedIndex = index;
    selectedCategoryId = categoryId;
  }

  /// Reset selection to initial state
  bool _resetSelection() {
    if (selectedIndex != 0 || selectedCategoryId != null) {
      selectedIndex = 0;
      selectedCategoryId = null;
      return true;
    }
    return false;
  }

  /// Resolve the current selected category ID
  String? _resolveCurrentSelectedId({
    required List<Category> previousCategories,
    required List<Category> nextCategories,
  }) {
    if (selectedCategoryId != null) {
      return selectedCategoryId;
    }

    if (previousCategories.isNotEmpty &&
        selectedIndex < previousCategories.length) {
      return previousCategories[selectedIndex].id;
    }

    return nextCategories.isNotEmpty ? nextCategories.first.id : null;
  }

  CategorySelectionManager copyWith({
    int? selectedIndex,
    String? selectedCategoryId,
  }) {
    return CategorySelectionManager(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    );
  }
}
