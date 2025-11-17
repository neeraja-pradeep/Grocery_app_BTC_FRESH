// // lib/features/wishlist/application/providers/wishlist_provider.dart

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:new_app/features/home/domain/entities/wishlist_item.dart';
// import 'package:new_app/features/home/domain/repositories/wishlist_repository.dart';
// import 'package:new_app/features/home/infrastructure/data_sources/remote/wishlist_api.dart';
// import 'package:new_app/features/home/infrastructure/repositories/home_repostory_impl.dart';
// import 'package:new_app/features/home/infrastructure/repositories/wishlist_repository_impl.dart';
// import 'package:new_app/features/home/application/usecases/wishlist_usecases.dart';
// import 'package:new_app/features/home/application/states/wishlist_state.dart';

// // Repository Provider
// final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
//   final dataSource = ref.watch(wishlistDataSourceProvider);
//   return WishlistRepositoryImpl(dataSource);
// });

// // Use Case Providers
// final getWishlistUseCaseProvider = Provider<GetWishlistUseCase>((ref) {
//   final repository = ref.watch(wishlistRepositoryProvider);
//   return GetWishlistUseCase(repository);
// });

// final addToWishlistUseCaseProvider = Provider<AddToWishlistUseCase>((ref) {
//   final repository = ref.watch(wishlistRepositoryProvider);
//   return AddToWishlistUseCase(repository);
// });

// final removeFromWishlistUseCaseProvider = Provider<RemoveFromWishlistUseCase>((
//   ref,
// ) {
//   final repository = ref.watch(wishlistRepositoryProvider);
//   return RemoveFromWishlistUseCase(repository);
// });

// // State Notifier
// class WishlistNotifier extends StateNotifier<WishlistState> {
//   final GetWishlistUseCase _getWishlistUseCase;
//   final AddToWishlistUseCase _addToWishlistUseCase;
//   final RemoveFromWishlistUseCase _removeFromWishlistUseCase;

//   WishlistNotifier(
//     this._getWishlistUseCase,
//     this._addToWishlistUseCase,
//     this._removeFromWishlistUseCase,
//   ) : super(const WishlistState()) {
//     loadWishlist();
//   }

//   Future<void> loadWishlist() async {
//     try {
//       state = state.copyWith(isLoading: true, error: null);
//       final items = await _getWishlistUseCase.execute();
//       state = state.copyWith(items: items, isLoading: false);
//     } catch (e) {
//       state = state.copyWith(isLoading: false, error: e.toString());
//     }
//   }

//   Future<void> addToWishlist(String productId) async {
//     try {
//       await _addToWishlistUseCase.execute(productId);
//       // Reload the wishlist to get updated data
//       await loadWishlist();
//     } catch (e) {
//       state = state.copyWith(error: e.toString());
//       rethrow;
//     }
//   }

//   Future<void> removeFromWishlist(String id) async {
//     try {
//       await _removeFromWishlistUseCase.execute(id);
//       // Reload the wishlist to get updated data
//       await loadWishlist();
//     } catch (e) {
//       state = state.copyWith(error: e.toString());
//       rethrow;
//     }
//   }

//   bool isInWishlist(String productId) {
//     return state.isInWishlist(productId);
//   }

//   void clearError() {
//     state = state.copyWith(error: null);
//   }
// }

// // Main Provider
// final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>(
//   (ref) {
//     final getWishlistUseCase = ref.watch(getWishlistUseCaseProvider);
//     final addToWishlistUseCase = ref.watch(addToWishlistUseCaseProvider);
//     final removeFromWishlistUseCase = ref.watch(
//       removeFromWishlistUseCaseProvider,
//     );

//     return WishlistNotifier(
//       getWishlistUseCase,
//       addToWishlistUseCase,
//       removeFromWishlistUseCase,
//     );
//   },
// );
