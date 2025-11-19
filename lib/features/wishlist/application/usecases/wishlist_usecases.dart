// // lib/features/wishlist/application/usecases/wishlist_usecases.dart

// import 'package:new_app/features/wishlist/domain/entities/wishlist_item.dart';
// import 'package:new_app/features/home/domain/repositories/wishlist_repository.dart';

// class GetWishlistUseCase {
//   final WishlistRepository _repository;

//   GetWishlistUseCase(this._repository);

//   Future<List<WishlistItem>> execute() {
//     return _repository.getWishlist();
//   }
// }

// class AddToWishlistUseCase {
//   final WishlistRepository _repository;

//   AddToWishlistUseCase(this._repository);

//   Future<WishlistItem> execute(String productId) {
//     return _repository.addToWishlist(productId);
//   }
// }

// class RemoveFromWishlistUseCase {
//   final WishlistRepository _repository;

//   RemoveFromWishlistUseCase(this._repository);

//   Future<void> execute(String id) {
//     return _repository.removeFromWishlist(id);
//   }
// }

// class GetWishlistItemUseCase {
//   final WishlistRepository _repository;

//   GetWishlistItemUseCase(this._repository);

//   Future<WishlistItem> execute(String id) {
//     return _repository.getWishlistItem(id);
//   }
// }

// class UpdateWishlistItemUseCase {
//   final WishlistRepository _repository;

//   UpdateWishlistItemUseCase(this._repository);

//   Future<WishlistItem> execute(String id, Map<String, dynamic> data) {
//     return _repository.updateWishlistItem(id, data);
//   }
// }
