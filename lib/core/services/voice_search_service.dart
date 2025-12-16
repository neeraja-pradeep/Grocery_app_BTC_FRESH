// lib/core/services/voice_search_service.dart

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Service class for handling speech-to-text functionality
class VoiceSearchService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  /// Check if speech recognition is available on this device
  bool get isAvailable => _isInitialized;

  /// Check if currently listening
  bool get isListening => _speechToText.isListening;

  /// Initialize the speech-to-text service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    _isInitialized = await _speechToText.initialize(
      onError: (error) {
        // Log error for debugging
        // print('Speech recognition error: ${error.errorMsg}');
      },
      onStatus: (status) {
        // Log status for debugging
        // print('Speech recognition status: $status');
      },
    );

    return _isInitialized;
  }

  /// Start listening for speech input
  Future<void> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
    String localeId = 'en_US',
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    await _speechToText.listen(
      onResult: onResult,
      localeId: localeId,
      listenFor: listenFor,
      pauseFor: pauseFor,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.search,
      ),
    );
  }

  /// Stop listening for speech input
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  /// Cancel listening without processing
  Future<void> cancelListening() async {
    await _speechToText.cancel();
  }

  /// Get available locales for speech recognition
  Future<List<LocaleName>> getLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speechToText.locales();
  }

  /// Dispose the service
  void dispose() {
    _speechToText.cancel();
  }
}
