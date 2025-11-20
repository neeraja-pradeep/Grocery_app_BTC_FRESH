import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { online, offline, unknown }

/// Provider that monitors internet connectivity status
final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) async* {
  final connectivity = Connectivity();

  // Check initial connectivity
  yield await _getConnectivityStatus(await connectivity.checkConnectivity());

  // Listen for connectivity changes
  await for (final result in connectivity.onConnectivityChanged) {
    yield await _getConnectivityStatus(result);
  }
});

/// Provider that returns the current connectivity status (single value, not streaming)
final connectivityStatusProvider = FutureProvider<ConnectivityStatus>((
  ref,
) async {
  final connectivity = Connectivity();
  return _getConnectivityStatus(await connectivity.checkConnectivity());
});

Future<ConnectivityStatus> _getConnectivityStatus(dynamic result) async {
  // Handle both single value and list of values for compatibility
  final List<ConnectivityResult> results;
  if (result is ConnectivityResult) {
    results = [result];
  } else if (result is List) {
    results = List<ConnectivityResult>.from(result);
  } else {
    return ConnectivityStatus.unknown;
  }

  if (results.contains(ConnectivityResult.none)) {
    return ConnectivityStatus.offline;
  }

  if (results.contains(ConnectivityResult.wifi) ||
      results.contains(ConnectivityResult.mobile) ||
      results.contains(ConnectivityResult.ethernet)) {
    return ConnectivityStatus.online;
  }

  return ConnectivityStatus.unknown;
}
