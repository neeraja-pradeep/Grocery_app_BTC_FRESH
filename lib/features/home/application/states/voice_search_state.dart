// lib/features/home/application/states/voice_search_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'voice_search_state.freezed.dart';

@freezed
sealed class VoiceSearchState with _$VoiceSearchState {
  /// Initial idle state
  const factory VoiceSearchState.idle() = VoiceSearchIdle;

  /// Initializing speech recognition
  const factory VoiceSearchState.initializing() = VoiceSearchInitializing;

  /// Actively listening for voice input
  const factory VoiceSearchState.listening({
    @Default('') String partialText,
    @Default(0.0) double soundLevel,
  }) = VoiceSearchListening;

  /// Processing recognized speech
  const factory VoiceSearchState.processing({required String recognizedText}) =
      VoiceSearchProcessing;

  /// Speech recognition completed successfully
  const factory VoiceSearchState.completed({required String recognizedText}) =
      VoiceSearchCompleted;

  /// Speech recognition not available on device
  const factory VoiceSearchState.notAvailable() = VoiceSearchNotAvailable;

  /// Permission denied for microphone
  const factory VoiceSearchState.permissionDenied() =
      VoiceSearchPermissionDenied;

  /// Error occurred during speech recognition
  const factory VoiceSearchState.error({required String message}) =
      VoiceSearchError;
}
