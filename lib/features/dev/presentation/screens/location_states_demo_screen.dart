// lib/features/dev/presentation/screens/location_states_demo_screen.dart
//
// Demo screen for QA: exercises all seven UI states defined for the location
// flow (loading, success, service-disabled, permission-denied,
// permission-denied-forever, timeout, low-accuracy) by reading directly from
// `locationProvider`. Toggle device GPS / app permission to walk through
// states 1–5, and use the buttons below to simulate timeout / low-accuracy
// without touching device settings.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/location_provider.dart';
import '../../../../core/location/location_service.dart';

class LocationStatesDemoScreen extends ConsumerWidget {
  const LocationStatesDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationProvider);
    final notifier = ref.read(locationProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Location states (dev)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current state',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _StateCard(state: state),
            const SizedBox(height: 24),
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => notifier.initialize(),
                  child: const Text('Initialize'),
                ),
                ElevatedButton(
                  onPressed: () => notifier.fetchCurrentLocation(),
                  child: const Text('Fetch (cached OK)'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      notifier.fetchCurrentLocation(forceFresh: true),
                  child: const Text('Fetch (forceFresh)'),
                ),
                ElevatedButton(
                  onPressed: () => notifier.requestPermission(),
                  child: const Text('Request permission'),
                ),
                ElevatedButton(
                  onPressed: () => notifier.openSettings(),
                  child: const Text('Open app settings'),
                ),
                ElevatedButton(
                  onPressed: () => notifier.openLocationSettings(),
                  child: const Text('Open OS location settings'),
                ),
                ElevatedButton(
                  onPressed: () => notifier.refresh(),
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Tips for reaching each UI state',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• loading: tap "Fetch (forceFresh)"\n'
              '• success: grant permission + GPS on, tap fetch\n'
              '• service-disabled: turn OFF device GPS, then fetch\n'
              '• permission-denied: deny permission once, then fetch\n'
              '• permission-denied-forever: deny + "don\'t ask again", then fetch\n'
              '• timeout: switch to airplane mode + GPS on, force fresh\n'
              '• low-accuracy: indoors with weak GPS (>100 m accuracy)',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateCard extends ConsumerWidget {
  const _StateCard({required this.state});

  final LocationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return state.when(
      initial: () => const _StateBox(
        title: 'INITIAL',
        body: 'Waiting for first call.',
        color: Colors.grey,
      ),
      loading: () => const _StateBox(
        title: 'LOADING',
        body: 'Fetching your location…',
        color: Colors.blue,
      ),
      permissionRequired: (status) {
        switch (status) {
          case LocationPermissionStatus.denied:
            return _StateBox(
              title: 'PERMISSION-DENIED',
              body: 'User can retry; OS prompt will reappear.',
              color: Colors.orange,
              cta: TextButton(
                onPressed: () =>
                    ref.read(locationProvider.notifier).requestPermission(),
                child: const Text('Retry'),
              ),
            );
          case LocationPermissionStatus.deniedForever:
            return _StateBox(
              title: 'PERMISSION-DENIED-FOREVER',
              body: 'Must be granted from app settings.',
              color: Colors.red,
              cta: TextButton(
                onPressed: () =>
                    ref.read(locationProvider.notifier).openSettings(),
                child: const Text('Open app settings'),
              ),
            );
          case LocationPermissionStatus.serviceDisabled:
            return _StateBox(
              title: 'SERVICE-DISABLED',
              body: 'Device GPS is off.',
              color: Colors.red,
              cta: TextButton(
                onPressed: () => ref
                    .read(locationProvider.notifier)
                    .openLocationSettings(),
                child: const Text('Open OS settings'),
              ),
            );
          case LocationPermissionStatus.granted:
            return const _StateBox(
              title: 'GRANTED (idle)',
              body: 'Tap fetch to get coordinates.',
              color: Colors.green,
            );
        }
      },
      loaded: (location) => _StateBox(
        title: 'SUCCESS',
        body:
            'lat: ${location.latitude.toStringAsFixed(5)}\n'
            'lng: ${location.longitude.toStringAsFixed(5)}\n'
            'accuracy: ${location.accuracy?.toStringAsFixed(1) ?? '?'} m\n'
            'timestamp: ${location.timestamp.toIso8601String()}',
        color: Colors.green,
      ),
      error: (failure, previousLocation) {
        if (failure is LocationTimeoutFailure) {
          return _StateBox(
            title: 'TIMEOUT',
            body: failure.message,
            color: Colors.deepOrange,
            cta: TextButton(
              onPressed: () => ref
                  .read(locationProvider.notifier)
                  .fetchCurrentLocation(forceFresh: true),
              child: const Text('Retry'),
            ),
          );
        }
        if (failure is LocationLowAccuracyFailure) {
          return _StateBox(
            title: 'LOW-ACCURACY',
            body:
                '${failure.message}\n'
                'lat: ${failure.location.latitude.toStringAsFixed(5)}\n'
                'lng: ${failure.location.longitude.toStringAsFixed(5)}\n'
                'accuracy: ${failure.location.accuracy?.toStringAsFixed(1) ?? '?'} m '
                '(threshold ${failure.thresholdMeters.toStringAsFixed(0)} m)',
            color: Colors.amber,
            cta: TextButton(
              onPressed: () => ref.read(locationProvider.notifier).refresh(),
              child: const Text('Refresh'),
            ),
          );
        }
        return _StateBox(
          title: 'UNKNOWN ERROR',
          body:
              '${failure.message}\n'
              '${previousLocation == null ? 'no fallback' : 'fallback available'}',
          color: Colors.red,
          cta: TextButton(
            onPressed: () => ref.read(locationProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        );
      },
    );
  }
}

class _StateBox extends StatelessWidget {
  const _StateBox({
    required this.title,
    required this.body,
    required this.color,
    this.cta,
  });

  final String title;
  final String body;
  final Color color;
  final Widget? cta;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 13)),
          if (cta != null) ...[const SizedBox(height: 6), cta!],
        ],
      ),
    );
  }
}
