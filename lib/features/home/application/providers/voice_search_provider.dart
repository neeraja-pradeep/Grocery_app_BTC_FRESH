// lib/features/home/application/providers/voice_search_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../../../core/services/voice_search_service.dart';
import '../states/voice_search_state.dart';

/// Provider for VoiceSearchService singleton
final voiceSearchServiceProvider = Provider<VoiceSearchService>((ref) {
  final service = VoiceSearchService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for VoiceSearchNotifier
final voiceSearchProvider =
    StateNotifierProvider.autoDispose<VoiceSearchNotifier, VoiceSearchState>((
      ref,
    ) {
      final service = ref.watch(voiceSearchServiceProvider);
      return VoiceSearchNotifier(service: service);
    });

/// Notifier for managing voice search state
class VoiceSearchNotifier extends StateNotifier<VoiceSearchState> {
  final VoiceSearchService _service;
  String _lastRecognizedText = '';

  VoiceSearchNotifier({required VoiceSearchService service})
    : _service = service,
      super(const VoiceSearchState.idle());

  /// Start voice search with permission handling
  Future<void> startVoiceSearch() async {
    // Check microphone permission first
    final permissionStatus = await Permission.microphone.status;

    // If denied or not yet requested, ask for permission
    if (permissionStatus.isDenied || permissionStatus.isRestricted) {
      final result = await Permission.microphone.request();

      if (result.isDenied || result.isPermanentlyDenied) {
        state = const VoiceSearchState.permissionDenied();
        return;
      }
    }

    // If permanently denied, user needs to enable it in settings
    if (permissionStatus.isPermanentlyDenied) {
      state = const VoiceSearchState.permissionDenied();
      return;
    }

    // Initialize speech recognition
    state = const VoiceSearchState.initializing();

    final isAvailable = await _service.initialize();

    if (!isAvailable) {
      state = const VoiceSearchState.notAvailable();
      return;
    }

    // Start listening
    state = const VoiceSearchState.listening();
    _lastRecognizedText = '';

    await _service.startListening(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  /// Handle speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;

    _lastRecognizedText = result.recognizedWords;

    if (result.finalResult) {
      // Final result - speech recognition completed
      if (_lastRecognizedText.isNotEmpty) {
        state = VoiceSearchState.completed(recognizedText: _lastRecognizedText);
      } else {
        state = const VoiceSearchState.idle();
      }
    } else {
      // Partial result - still listening
      state = VoiceSearchState.listening(partialText: _lastRecognizedText);
    }
  }

  /// Stop voice search and process results
  Future<void> stopVoiceSearch() async {
    await _service.stopListening();

    if (_lastRecognizedText.isNotEmpty) {
      state = VoiceSearchState.completed(recognizedText: _lastRecognizedText);
    } else {
      state = const VoiceSearchState.idle();
    }
  }

  /// Cancel voice search without processing
  Future<void> cancelVoiceSearch() async {
    await _service.cancelListening();
    _lastRecognizedText = '';
    state = const VoiceSearchState.idle();
  }

  /// Reset state to idle
  void reset() {
    _lastRecognizedText = '';
    state = const VoiceSearchState.idle();
  }

  /// Open app settings for permission
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
