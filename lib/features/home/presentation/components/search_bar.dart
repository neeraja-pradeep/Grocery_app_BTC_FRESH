// lib/features/home/presentation/components/search_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Renamed to CustomSearchBar to avoid conflict with Material 3 SearchBar
class CustomSearchBar extends ConsumerWidget {
  final ValueChanged<String> onTextSearch;
  final VoidCallback onVoiceSearch;

  /// When true, disables the text field input (useful when used as a tap target)
  final bool disableTextInput;

  const CustomSearchBar({
    super.key,
    required this.onTextSearch,
    required this.onVoiceSearch,
    this.disableTextInput = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/search.png',
            color: Colors.grey[600],
            height: 30.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: AbsorbPointer(
              absorbing: disableTextInput,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for "Rice"',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(fontSize: 14.sp),
                textInputAction: TextInputAction.search,
                onSubmitted: onTextSearch,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Container(height: 24.h, width: 1.w, color: Colors.grey[400]),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: onVoiceSearch,
            child: Icon(Icons.mic, color: const Color(0xff016064), size: 30.sp),
          ),
        ],
      ),
    );
  }
}
