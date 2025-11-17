// lib/features/categories/presentation/screen/categories_screen.dart

// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:new_app/features/home/application/providers/home_provider.dart';
// import 'package:new_app/features/home/domain/entities/category.dart';
// import 'package:new_app/features/home/presentation/screen/category_detail_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(body: const Center(child: Text("category")));
    // return Scaffold(
    //   backgroundColor: Colors.white,
    //   appBar: AppBar(
    //     title: const Text('Shop by Category'),
    //     backgroundColor: Colors.white,
    //     foregroundColor: Colors.black,
    //     elevation: 0,
    //     centerTitle: false,
    //     actions: [
    //       IconButton(
    //         icon: const Icon(Icons.search),
    //         onPressed: () {
    //           // TODO: Implement search
    //         },
    //       ),
    //     ],
    //   ),
    //   body: categories.isEmpty
    //       ? const Center(
    //           child: Column(
    //             mainAxisAlignment: MainAxisAlignment.center,
    //             children: [
    //               CircularProgressIndicator(),
    //               SizedBox(height: 16),
    //               Text('Loading categories...'),
    //             ],
    //           ),
    //         )
    //       : Padding(
    //           padding: const EdgeInsets.all(16.0),
    //           child: GridView.builder(
    //             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    //               crossAxisCount: 2,
    //               crossAxisSpacing: 16,
    //               mainAxisSpacing: 16,
    //               childAspectRatio: 0.85,
    //             ),
    //             itemCount: categories.length,
    //             itemBuilder: (context, index) {
    //               return _CategoryCard(category: categories[index]);
    //             },
    //           ),
    //         ),
    // );
  }
}

// class _CategoryCard extends StatelessWidget {
//   final Category category;

//   const _CategoryCard({required this.category});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => CategoryDetailScreen(category: category),
//           ),
//         );
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey.shade200),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.shade100,
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             // Category Image
//             Expanded(
//               flex: 3,
//               child: Container(
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   borderRadius: const BorderRadius.vertical(
//                     top: Radius.circular(12),
//                   ),
//                   color: Colors.grey.shade50,
//                 ),
//                 child: ClipRRect(
//                   borderRadius: const BorderRadius.vertical(
//                     top: Radius.circular(12),
//                   ),
//                   child:
//                       category.iconUrl?.isNotEmpty ==
//                           true // FIX APPLIED HERE
//                       ? Image.network(
//                           category
//                               .iconUrl!, // Use '!' since we checked for null
//                           fit: BoxFit.cover,
//                           errorBuilder: (context, error, stackTrace) {
//                             return const Icon(
//                               Icons.category,
//                               size: 40,
//                               color: Colors.green,
//                             );
//                           },
//                         )
//                       : const Icon(
//                           Icons.category,
//                           size: 40,
//                           color: Colors.green,
//                         ),
//                 ),
//               ),
//             ),
//             // Category Name
//             Expanded(
//               flex: 1,
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Center(
//                   child: Text(
//                     category.name,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                     ),
//                     textAlign: TextAlign.center,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
