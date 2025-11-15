/// Helper function to determine if a loading indicator should be shown
/// based on the refresh start and end times.
///
/// Returns true if either:
/// - The refresh started within the last 1500ms
/// - The refresh ended within the last 1500ms
bool shouldShowLoading({
  required DateTime? startedAt,
  required DateTime? endedAt,
}) {
  final now = DateTime.now();
  if (startedAt != null && now.difference(startedAt).inMilliseconds <= 1500) {
    return true;
  }
  if (endedAt != null && now.difference(endedAt).inMilliseconds <= 1500) {
    return true;
  }
  return false;
}
