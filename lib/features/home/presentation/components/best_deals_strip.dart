// // features/home/presentation/components/best_deals_strip.dart

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:new_app/features/home/presentation/components/product_card.dart';
// import 'package:new_app/features/home/presentation/components/section_header.dart';
// // IMPORT REAL PROVIDERS and ENTITIES
// import 'package:new_app/features/home/application/providers/home_provider.dart';

// // --- DUMMY DEFINITIONS REMOVED ---

// class BestDealsStrip extends ConsumerWidget {
//   const BestDealsStrip({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // WATCH THE REAL PROVIDER
//     final bestDeals = ref.watch(bestDealsProvider);

//     if (bestDeals.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Add consistent padding to match other sections
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 0.0),
//           child: SectionHeader(title: 'Best Deals', onSeeAll: () => {}),
//         ),
//         const SizedBox(height: 8),
//         SizedBox(
//           height: 200, // Fixed height for horizontal list
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: bestDeals.length,
//             itemBuilder: (context, index) {
//               final product_ = bestDeals[index];
//               return Padding(
//                 padding: EdgeInsets.only(
//                   left: index == 0
//                       ? 0.0
//                       : 8.0, // Remove extra left padding for first item
//                   right: 8.0,
//                 ),
//                 child: ProductCard(product: product_),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }
