// lib/features/home/application/providers/category_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/home_repository.dart';
import 'home_repository_provider.dart';

part 'category_provider.g.dart';

// Separate provider for category details (when user clicks "See All")
// @riverpod defaults to autoDispose: true, which is what we want.
@riverpod
class CategoryDetails extends _$CategoryDetails {
  late final HomeRepository _repository;

  @override
  AsyncValue<List<Category>> build() {
    _repository = ref.read(homeRepositoryProvider);

    // We trigger the initial load immediately upon creation
    // so the UI doesn't have to call it manually.
    loadAllCategories();

    return const AsyncValue.loading();
  }

  Future<void> loadAllCategories({int page = 1}) async {
    state = const AsyncValue.loading();

    final result = await _repository.getCategories(page: page);

    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (categories) => AsyncValue.data(categories),
    );
  }
}
