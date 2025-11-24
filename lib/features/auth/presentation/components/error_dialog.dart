import 'package:flutter/material.dart';
import 'package:grocery_app/core/error/failure.dart';

class ErrorDialog extends StatelessWidget {
  final Failure failure;

  const ErrorDialog({super.key, required this.failure});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
      title: const Text('Oops!'),
      content: Text(failure.displayMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
        if (_canRetry(failure))
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Retry'),
          ),
      ],
    );
  }

  bool _canRetry(Failure failure) {
    return failure is NetworkFailure ||
        failure is TimeoutFailure ||
        failure is ServerFailure;
  }
}
