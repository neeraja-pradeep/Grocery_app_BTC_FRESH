// lib/features/categories/presentation/screen/category_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:new_app/features/home/domain/entities/category.dart';

class CategoryDetailScreen extends StatelessWidget {
  final Category category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("category")));
  }
}

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(category.name),
//         backgroundColor: Colors.green,
//         foregroundColor: Colors.white,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Category icon/image placeholder
//             Container(
//               width: 120,
//               height: 120,
//               decoration: BoxDecoration(
//                 color: Colors.green.shade50,
//                 borderRadius: BorderRadius.circular(60),
//                 border: Border.all(color: Colors.green.shade200),
//               ),
//               child:
//                   category.iconUrl?.isNotEmpty ==
//                       true // FIX APPLIED HERE
//                   ? ClipRRect(
//                       borderRadius: BorderRadius.circular(60),
//                       child: Image.network(
//                         category.iconUrl!, // Use '!' since we checked for null
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) {
//                           return const Icon(
//                             Icons.category,
//                             size: 60,
//                             color: Colors.green,
//                           );
//                         },
//                       ),
//                     )
//                   : const Icon(Icons.category, size: 60, color: Colors.green),
//             ),
//             const SizedBox(height: 24),
//             Text(
//               category.name,
//               style: const TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Category ID: ${category.id}',
//               style: const TextStyle(fontSize: 14, color: Colors.grey),
//             ),
//             const SizedBox(height: 32),
//             const Text(
//               'Products in this category will be shown here',
//               style: TextStyle(fontSize: 16, color: Colors.grey),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 32,
//                   vertical: 12,
//                 ),
//               ),
//               child: const Text('Back to Home'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
