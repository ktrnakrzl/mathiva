import 'package:flutter/foundation.dart';

import 'progress_service.dart';

/// In-memory cache of the current user's aggregated progress, refreshed after
/// each submitted attempt and on demand. Mirrors AppPreferences' ValueNotifier
/// pattern so the (non-Riverpod) screen tree can `ValueListenableBuilder` on it.
///
/// `current.value == null` means "not yet loaded / fetch failed" -> screens
/// show a lightweight loading state. A loaded [UserProgress] with
/// `totalAttempts == 0` is the genuine zero-state for a brand-new user ->
/// screens render real zeros, not fake fallback numbers.
class ProgressStore {
  static final ValueNotifier<UserProgress?> current =
      ValueNotifier<UserProgress?>(null);

  static final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  /// Fetches fresh progress from the backend and updates [current]. Safe to
  /// call repeatedly (e.g. on every progress screen's init, and after each
  /// submitted attempt). On failure, leaves [current] as-is so screens keep
  /// rendering whatever they last had rather than crashing.
  static Future<void> refresh() async {
    isLoading.value = true;
    try {
      current.value = await ProgressService.getProgress();
    } catch (_) {
      // Network/auth error -- leave `current` unchanged (possibly null).
    } finally {
      isLoading.value = false;
    }
  }
}
