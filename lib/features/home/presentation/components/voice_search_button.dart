// features/home/presentation/components/voice_search_button.dart

import 'package:flutter/material.dart';

class VoiceSearchButton extends StatelessWidget {
  final VoidCallback onStartVoiceSearch;

  const VoiceSearchButton({super.key, required this.onStartVoiceSearch});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.mic, color: Colors.green, size: 20),
      onPressed: onStartVoiceSearch,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40),
    );
  }
}
