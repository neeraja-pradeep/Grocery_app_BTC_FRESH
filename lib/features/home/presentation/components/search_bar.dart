// features/home/presentation/components/search_bar.dart

import 'dart:async';
import 'package:flutter/material.dart';

import 'package:new_app/features/home/presentation/components/voice_search_button.dart';
// ---------------------------

class CustomSearchBar extends StatefulWidget {
  final ValueChanged<String> onSubmitSearch;
  final VoidCallback onStartVoiceSearch;
  final TextEditingController controller;

  const CustomSearchBar({
    super.key,
    required this.onSubmitSearch,
    required this.onStartVoiceSearch,
    required this.controller,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  // Timer for input debouncing
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  void dispose() {
    _debounceTimer?.cancel();
    // Note: The controller is managed (disposed) by the parent (HomeScreenState)
    super.dispose();
  }

  void _onQueryChanged(String query) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    // Debounce the submission for performance while typing
    _debounceTimer = Timer(_debounceDuration, () {
      // Placeholder for live search, if needed. For now, we only submit on ENTER/Voice
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Change height to 56px as indicated in the image
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          10,
        ), // Reduced radius for a boxier look
        boxShadow: [
          // Minimal or no shadow for a flatter look
          BoxShadow(
            color: Colors.black12.withValues(alpha: 0.02), // Very subtle shadow
            spreadRadius: 0.5,
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Icon(
              Icons.search,
              color: Colors.grey,
              size: 24,
            ), // Slightly larger icon
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              onChanged: _onQueryChanged, // Debounce placeholder logic
              onSubmitted: widget.onSubmitSearch, // Final submission on ENTER
              // Align the hint text vertically
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                hintText: "Search For 'Cooker'",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
                isDense: true,
              ),
            ),
          ),
          // Ensure the VoiceSearchButton is imported and used
          VoiceSearchButton(onStartVoiceSearch: widget.onStartVoiceSearch),
        ],
      ),
    );
  }
}
