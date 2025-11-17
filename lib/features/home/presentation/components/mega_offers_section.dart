// features/home/presentation/components/mega_offers_section.dart

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_card.dart';
// IMPORT REAL PROVIDERS and ENTITIES
import 'package:new_app/features/home/application/providers/home_provider.dart';
import 'package:new_app/features/home/domain/entities/offer.dart';

// --- DUMMY DEFINITIONS REMOVED ---

// Helper to group offers by category (since the provider returns a flat List<Offer>)
Map<String, List<Offer>> _groupOffersByCategories(List<Offer> offers) {
  final Map<String, List<Offer>> grouped = {};
  for (var offer in offers) {
    // NOTE: This assumes your Offer entity has a 'category' field.
    final category = offer.category ?? 'Uncategorized';
    if (!grouped.containsKey(category)) {
      grouped[category] = [];
    }
    grouped[category]!.add(offer);
  }
  return grouped;
}

class MegaOffersSection extends ConsumerWidget {
  const MegaOffersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 3. WATCH THE REAL PROVIDER (raw list of Offers)
    final allOffers = ref.watch(megaOffersProvider);

    // 4. PERFORM LOCAL GROUPING LOGIC
    final groupedOffers = _groupOffersByCategories(allOffers);

    if (groupedOffers.isEmpty) {
      return const SizedBox.shrink();
    }

    // Build the main vertical list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Global Mega Offers Header
        const Padding(
          padding: EdgeInsets.only(top: 24, bottom: 12),
          child: Center(
            child: Text(
              'MEGA FRESH OFFERS',
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: Color(0xff016064),
              ),
            ),
          ),
        ),

        // Iterate over categories and build sections
        ...groupedOffers.keys.map((category) {
          final products = groupedOffers[category]!;
          return _buildCategorySection(context, category, products);
        }),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    List<Offer> products, // Use Offer type
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
        ),

        // Product Horizontal Scrollable List
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: index == products.length - 1 ? 16.0 : 0.0,
                ),
                child: SizedBox(
                  width: 100,
                  // Pass the Offer object to the MegaOfferProductCard
                  child: MegaOfferProductCard(product: products[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
