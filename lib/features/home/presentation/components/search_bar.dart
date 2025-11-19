// lib/features/home/presentation/components/search_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Renamed to CustomSearchBar to avoid conflict with Material 3 SearchBar
class CustomSearchBar extends ConsumerWidget {
  final ValueChanged<String> onTextSearch;
  final VoidCallback onVoiceSearch;

  const CustomSearchBar({
    super.key,
    required this.onTextSearch,
    required this.onVoiceSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for "Rice"',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 14),
              textInputAction: TextInputAction.search,
              onSubmitted: onTextSearch,
            ),
          ),
          const SizedBox(width: 8),
          Container(height: 24, width: 1, color: Colors.grey[300]),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onVoiceSearch,
            child: const Icon(Icons.mic, color: Colors.green),
          ),
        ],
      ),
    );
  }
}
