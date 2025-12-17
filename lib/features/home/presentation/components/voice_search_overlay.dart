// lib/features/home/presentation/components/voice_search_overlay.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../application/providers/voice_search_provider.dart';
import '../../application/states/voice_search_state.dart';

/// Shows a voice search overlay dialog
/// Returns the recognized text or null if cancelled
Future<String?> showVoiceSearchOverlay(BuildContext context) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (context) => const _VoiceSearchDialog(),
  );
}

class _VoiceSearchDialog extends ConsumerStatefulWidget {
  const _VoiceSearchDialog();

  @override
  ConsumerState<_VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends ConsumerState<_VoiceSearchDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start voice search when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceSearchProvider.notifier).startVoiceSearch();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceSearchProvider);

    // Listen for state changes to auto-close on completion
    ref.listen<VoiceSearchState>(voiceSearchProvider, (previous, next) {
      next.maybeWhen(
        completed: (text) {
          // Return the recognized text and close
          Navigator.of(context).pop(text);
        },
        orElse: () {},
      );
    });

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              voiceState.maybeWhen(
                listening: (text, level) => 'Listening...',
                initializing: () => 'Starting...',
                processing: (_) => 'Processing...',
                notAvailable: () => 'Not Available',
                permissionDenied: () => 'Permission Required',
                error: (_) => 'Error',
                orElse: () => 'Voice Search',
              ),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0b6866),
              ),
            ),

            SizedBox(height: 24.h),

            // Animated microphone icon
            voiceState.when(
              idle: () => _buildMicIcon(false),
              initializing: () => _buildLoadingIndicator(),
              listening: (partialText, soundLevel) =>
                  _buildListeningUI(partialText),
              processing: (text) => _buildProcessingUI(text),
              completed: (_) => _buildMicIcon(false),
              notAvailable: () => _buildNotAvailableUI(),
              permissionDenied: () => _buildPermissionDeniedUI(),
              error: (message) => _buildErrorUI(message),
            ),

            SizedBox(height: 24.h),

            // Action buttons
            voiceState.maybeWhen(
              listening: (text, level) => _buildListeningButtons(),
              permissionDenied: () => _buildPermissionButtons(),
              notAvailable: () => _buildCloseButton(),
              error: (_) => _buildRetryButtons(),
              orElse: () => _buildCloseButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicIcon(bool isActive) {
    return Container(
      width: 80.w,
      height: 80.w,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF0b6866)
            : const Color(0xFF0b6866).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.mic,
        size: 40.sp,
        color: isActive ? Colors.white : const Color(0xFF0b6866),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 80.w,
      height: 80.w,
      child: const CircularProgressIndicator(
        color: Color(0xFF0b6866),
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildListeningUI(String partialText) {
    return Column(
      children: [
        // Animated mic icon
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 80.w,
            height: 80.w,
            decoration: const BoxDecoration(
              color: Color(0xFF0b6866),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mic, size: 40.sp, color: Colors.white),
          ),
        ),
        if (partialText.isNotEmpty) ...[
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              partialText,
              style: TextStyle(fontSize: 16.sp, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        SizedBox(height: 12.h),
        Text(
          'Speak now...',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildProcessingUI(String text) {
    return Column(
      children: [
        _buildLoadingIndicator(),
        SizedBox(height: 16.h),
        Text(
          text,
          style: TextStyle(fontSize: 16.sp, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNotAvailableUI() {
    return Column(
      children: [
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.mic_off, size: 40.sp, color: Colors.red),
        ),
        SizedBox(height: 16.h),
        Text(
          'Speech recognition is not available on this device',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPermissionDeniedUI() {
    return Column(
      children: [
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.mic_off, size: 40.sp, color: Colors.orange),
        ),
        SizedBox(height: 16.h),
        Text(
          'Microphone permission is required for voice search',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorUI(String message) {
    return Column(
      children: [
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.error_outline, size: 40.sp, color: Colors.red),
        ),
        SizedBox(height: 16.h),
        Text(
          message,
          style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildListeningButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Cancel button
        TextButton(
          onPressed: () {
            ref.read(voiceSearchProvider.notifier).cancelVoiceSearch();
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancel',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
        ),
        // Done button
        ElevatedButton(
          onPressed: () {
            ref.read(voiceSearchProvider.notifier).stopVoiceSearch();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0b6866),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: Text(
            'Done',
            style: TextStyle(fontSize: 16.sp, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(voiceSearchProvider.notifier).openSettings();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0b6866),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: Text(
            'Open Settings',
            style: TextStyle(fontSize: 16.sp, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildRetryButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(voiceSearchProvider.notifier).startVoiceSearch();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0b6866),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: Text(
            'Retry',
            style: TextStyle(fontSize: 16.sp, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton() {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text(
        'Close',
        style: TextStyle(fontSize: 16.sp, color: const Color(0xFF0b6866)),
      ),
    );
  }
}
