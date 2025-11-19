// lib/features/home/application/providers/category_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:new_app/features/home/domain/entities/category.dart';
import 'package:new_app/features/home/domain/repositories/home_repository.dart';
import 'package:new_app/features/home/infrastructure/repositories/home_repostory_impl.dart';

part 'category_provider.g.dart';

// Separate provider for category details (when user clicks "See All")
// @riverpod defaults to autoDispose: true, which is what we want.
@riverpod
class CategoryDetails extends _$CategoryDetails {
  late final HomeRepository _repository;

  // Internal state to track current page since PaginatedResult stores URLs
  int _currentPage = 1;

  @override
  AsyncValue<PaginatedResult<Category>> build() {
    _repository = ref.read(homeRepositoryProvider);

    // We trigger the initial load immediately upon creation
    // so the UI doesn't have to call it manually.
    loadAllCategories();

    return const AsyncValue.loading();
  }

  Future<void> loadAllCategories({int page = 1}) async {
    _currentPage = page;
    state = const AsyncValue.loading();

    final result = await _repository.getCategories(page: page);

    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (paginatedResult) => AsyncValue.data(paginatedResult),
    );
  }

  Future<void> loadMore() async {
    // 1. Check if we have valid data currently
    if (!state.hasValue) return;
    final currentData = state.value!;

    // 2. Check if there is a next page (using the 'next' URL field)
    if (currentData.next == null) return;

    // 3. Fetch next page
    final nextPage = _currentPage + 1;
    final result = await _repository.getCategories(page: nextPage);

    result.fold(
      (failure) {
        // On failure, we keep the current state (user can retry)
        // Optionally, could set state to AsyncValue.error, but that wipes the list.
        // Ideally, handle this with a side-effect/snackbar controller.
      },
      (newPageData) {
        _currentPage = nextPage;

        // 4. Merge the new results with the existing results
        state = AsyncValue.data(
          PaginatedResult(
            count: newPageData.count,
            next: newPageData.next,
            previous: newPageData.previous,
            results: [...currentData.results, ...newPageData.results],
          ),
        );
      },
    );
  }
}
