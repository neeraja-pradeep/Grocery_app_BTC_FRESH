import '../../domain/entities/category.dart';

/// Immutable manager for category selection state.
/// All mutations return a new instance; never modifies in place.
class CategorySelectionManager {
  final int selectedIndex;
  final String? selectedCategoryId;

  const CategorySelectionManager({
    this.selectedIndex = 0,
    this.selectedCategoryId,
  });

  /// Returns a new manager with updated selection if it changed, or null if unchanged.
  CategorySelectionManager? tryUpdateSelection({
    required List<Category> previousCategories,
    required List<Category> nextCategories,
  }) {
    if (nextCategories.isEmpty) {
      return _tryReset();
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
      return copyWith(selectedIndex: targetIndex, selectedCategoryId: targetId);
    }

    return null;
  }

  CategorySelectionManager copyWith({
    int? selectedIndex,
    String? selectedCategoryId,
    bool clearCategoryId = false,
  }) {
    return CategorySelectionManager(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      selectedCategoryId: clearCategoryId
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
    );
  }

  CategorySelectionManager? _tryReset() {
    if (selectedIndex != 0 || selectedCategoryId != null) {
      return const CategorySelectionManager();
    }
    return null;
  }

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
}
