/// Formats a duration in seconds as a compact human string:
/// `45s`, `1m 58s`, `2h 15m`. Shared by the result screen and the
/// progress/analytics screens so the same logic isn't duplicated.
String formatElapsed(int seconds) {
  if (seconds < 60) return '${seconds}s';
  if (seconds < 3600) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes}m ${remainder}s';
  }
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  return '${hours}h ${minutes}m';
}
