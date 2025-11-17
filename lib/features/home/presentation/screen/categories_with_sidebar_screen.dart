// lib/features/home/presentation/screen/categories_with_sidebar_screen.dart

// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_app/features/home/application/providers/home_provider.dart';
import 'package:new_app/features/home/domain/entities/category.dart';
// import 'package:new_app/features/home/domain/entities/product.dart';
// import 'package:new_app/features/home/presentation/components/category_sidebar.dart';
// import 'package:new_app/features/home/presentation/components/product_card.dart';
// import 'package:new_app/features/wishlist/application/providers/wishlist_provider.dart';

class CategoriesWithSidebarScreen extends ConsumerStatefulWidget {
  const CategoriesWithSidebarScreen({super.key});

  @override
  ConsumerState<CategoriesWithSidebarScreen> createState() =>
      _CategoriesWithSidebarScreenState();
}

class _CategoriesWithSidebarScreenState
    extends ConsumerState<CategoriesWithSidebarScreen> {
  Category? selectedCategory;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Select first category by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categories = ref.read(categoriesProvider);
      if (categories.isNotEmpty && selectedCategory == null) {
        setState(() {
          selectedCategory = categories.first;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // final categories = ref.watch(categoriesProvider);
    // final products = ref.watch(
    //   bestDealsProvider,
    // ); // Using best deals as sample products

    //   // Filter products based on search query
    //   final filteredProducts = products.where((product) {
    //     return searchQuery.isEmpty ||
    //         product.name.toLowerCase().contains(searchQuery.toLowerCase());
    //   }).toList();
    return Scaffold(body: const Center(child: Text("category")));
  }

  // }
}
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text(
//           'Shop By Category',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//             color: Colors.black,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,
//         centerTitle: false,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search),
//             onPressed: () {
//               // Show search functionality
//             },
//           ),
//         ],
//       ),
//       body: Row(
//         children: [
//           // Sidebar
//           CategorySidebar(
//             selectedCategory: selectedCategory,
//             onCategorySelected: (category) {
//               setState(() {
//                 selectedCategory = category;
//               });
//             },
//           ),
//           // Main Content
//           Expanded(
//             child: Column(
//               children: [
//                 // Search Bar
//                 Container(
//                   margin: const EdgeInsets.all(16),
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade100,
//                     borderRadius: BorderRadius.circular(25),
//                   ),
//                   child: TextField(
//                     onChanged: (value) {
//                       setState(() {
//                         searchQuery = value;
//                       });
//                     },
//                     decoration: const InputDecoration(
//                       hintText: 'Search products...',
//                       border: InputBorder.none,
//                       icon: Icon(Icons.search, color: Colors.grey),
//                     ),
//                   ),
//                 ),
//                 // Category Header
//                 if (selectedCategory != null)
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: Row(
//                       children: [
//                         Text(
//                           selectedCategory!.name,
//                           style: const TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black,
//                           ),
//                         ),
//                         const Spacer(),
//                         TextButton(
//                           onPressed: () {
//                             // Show all products in category
//                           },
//                           child: const Text(
//                             'See all',
//                             style: TextStyle(
//                               color: Colors.green,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 // Products Grid
//                 Expanded(
//                   child: filteredProducts.isEmpty
//                       ? const Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.shopping_basket_outlined,
//                                 size: 64,
//                                 color: Colors.grey,
//                               ),
//                               SizedBox(height: 16),
//                               Text(
//                                 'No products found',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         )
//                       : Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: GridView.builder(
//                             gridDelegate:
//                                 const SliverGridDelegateWithFixedCrossAxisCount(
//                                   crossAxisCount: 2,
//                                   crossAxisSpacing: 16,
//                                   mainAxisSpacing: 16,
//                                   childAspectRatio: 0.85,
//                                 ),
//                             itemCount: categories.length,
//                             itemBuilder: (context, index) {
//                               // Use the centralized CategoryItemCard
//                               return CategoryItemCard(
//                                 category: categories[index],
//                               );
//                             },
//                           ),
//                         ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _CategoryProductCard extends ConsumerWidget {
//   final Product product;

//   const _CategoryProductCard({required this.product});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final wishlistNotifier = ref.read(wishlistProvider.notifier);
//     final isInWishlist = ref
//         .watch(wishlistProvider.notifier)
//         .isInWishlist(product.id.toString());

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade200),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.05),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Product Image with Add Button
//           Expanded(
//             flex: 3,
//             child: Stack(
//               children: [
//                 Container(
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     borderRadius: const BorderRadius.vertical(
//                       top: Radius.circular(12),
//                     ),
//                     color: Colors.grey.shade50,
//                   ),
//                   child: ClipRRect(
//                     borderRadius: const BorderRadius.vertical(
//                       top: Radius.circular(12),
//                     ),
//                     child: product.imageUrl.isNotEmpty
//                         ? Image.network(
//                             product.imageUrl,
//                             fit: BoxFit.cover,
//                             errorBuilder: (context, error, stackTrace) {
//                               return const Icon(
//                                 Icons.image_not_supported,
//                                 size: 40,
//                                 color: Colors.grey,
//                               );
//                             },
//                             loadingBuilder: (context, child, loadingProgress) {
//                               if (loadingProgress == null) return child;
//                               return const Center(
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                 ),
//                               );
//                             },
//                           )
//                         : const Icon(
//                             Icons.image_not_supported,
//                             size: 40,
//                             color: Colors.grey,
//                           ),
//                   ),
//                 ),
//                 // Add to Cart Button
//                 Positioned(
//                   top: 8,
//                   right: 8,
//                   child: GestureDetector(
//                     onTap: () async {
//                       try {
//                         if (isInWishlist) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text('Already in wishlist'),
//                             ),
//                           );
//                         } else {
//                           await wishlistNotifier.addToWishlist(
//                             product.id.toString(),
//                           );
//                           if (context.mounted) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text(
//                                   '${product.name} added to wishlist',
//                                 ),
//                               ),
//                             );
//                           }
//                         }
//                       } catch (e) {
//                         if (context.mounted) {
//                           ScaffoldMessenger.of(
//                             context,
//                           ).showSnackBar(SnackBar(content: Text('Error: $e')));
//                         }
//                       }
//                     },
//                     child: Container(
//                       width: 32,
//                       height: 32,
//                       decoration: BoxDecoration(
//                         color: isInWishlist ? Colors.red : Colors.green,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withValues(alpha: 0.1),
//                             blurRadius: 4,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: Icon(
//                         isInWishlist ? Icons.favorite : Icons.add,
//                         color: Colors.white,
//                         size: 18,
//                       ),
//                     ),
//                   ),
//                 ),
//                 // Custom heart icon for removal in the image
//                 if (isInWishlist)
//                   Positioned(
//                     top: 8,
//                     right: 8,
//                     child: Container(
//                       width: 32,
//                       height: 32,
//                       decoration: BoxDecoration(
//                         color: Colors
//                             .red, // Red Circle for Wishlist (as seen in image)
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withValues(alpha: 0.1),
//                             blurRadius: 4,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: const Icon(
//                         Icons.favorite,
//                         color: Colors.white,
//                         size: 18,
//                       ),
//                     ),
//                   ),
//                 // 50% OFF Badge (based on provided image)
//                 Positioned(
//                   bottom: 8,
//                   right: 8,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 6,
//                       vertical: 2,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.green.shade100,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Text(
//                       '50% OFF', // Hardcoded as per image, replace with actual discount logic
//                       style: TextStyle(
//                         fontSize: 10,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.green.shade700,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Product Details
//           Expanded(
//             flex: 1, // ADJUSTED FLEX RATIO: Less space for details
//             child: Padding(
//               padding: const EdgeInsets.all(8), // REDUCED PADDING from 12 to 8
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     product.name,
//                     style: const TextStyle(
//                       fontSize: 12, // REDUCED FONT SIZE from 14 to 12
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black87,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     product.unitLabel,
//                     style: TextStyle(
//                       fontSize: 10,
//                       color: Colors.grey.shade600,
//                     ), // REDUCED FONT SIZE from 12 to 10
//                   ),
//                   const Spacer(),
//                   Row(
//                     children: [
//                       Text(
//                         '₹${product.price.toStringAsFixed(0)}',
//                         style: const TextStyle(
//                           fontSize: 14, // REDUCED FONT SIZE from 16 to 14
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                       ),
//                       const SizedBox(width: 4), // REDUCED SPACING from 8 to 4
//                       if (product.mrp > product.price)
//                         Text(
//                           '₹${product.mrp.toStringAsFixed(0)}',
//                           style: TextStyle(
//                             fontSize: 10, // REDUCED FONT SIZE from 12 to 10
//                             color: Colors.grey.shade600,
//                             decoration: TextDecoration.lineThrough,
//                           ),
//                         ),
//                       const Spacer(),
//                       if (product.discountPct > 0)
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 6,
//                             vertical: 2,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.green.shade100,
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Text(
//                             '${product.discountPct}% OFF',
//                             style: TextStyle(
//                               fontSize: 10,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.green.shade700,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
