import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mathiva_models.dart';

/// One solved scan, shown under "Recent" on the home screen.
class ScanHistoryEntry {
  final String question; // detected equation/expression, e.g. "\(2x + 3 = 13\)"
  final String answer; //   e.g. "\(x = 5\)"
  final List<String> steps; // the worked steps, so the row can reopen the solution
  final DateTime solvedAt;

  const ScanHistoryEntry({
    required this.question,
    required this.answer,
    required this.steps,
    required this.solvedAt,
  });

  /// Rebuild the solved problem so tapping a recent row reopens its solution.
  PracticeProblem toProblem() =>
      PracticeProblem(question: question, answer: answer, steps: steps);

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
        'steps': steps,
        'solvedAt': solvedAt.millisecondsSinceEpoch,
      };

  factory ScanHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ScanHistoryEntry(
        question: json['question'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
        steps: (json['steps'] as List?)?.map((s) => s.toString()).toList() ??
            const [],
        solvedAt: DateTime.fromMillisecondsSinceEpoch(
            (json['solvedAt'] as num?)?.toInt() ?? 0),
      );
}

/// Persists the student's most recent solved scans on-device
/// (shared_preferences), so the home screen's "Recent" list reflects real
/// activity instead of hardcoded samples. The backend has no solve-history
/// endpoint, so this is the local equivalent -- same approach as [AuthStorage].
class ScanHistoryService {
  static const _key = 'scan_history_v1';
  static const _maxEntries = 5;

  /// Reactive view for the home screen; refreshed by [load] and [record].
  static final ValueNotifier<List<ScanHistoryEntry>> recent =
      ValueNotifier<List<ScanHistoryEntry>>(const []);

  /// Load persisted history into [recent]. Call once at startup.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      recent.value = const [];
      return;
    }
    try {
      recent.value = (jsonDecode(raw) as List)
          .map((e) => ScanHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt/legacy payload -- start clean rather than crash the home screen.
      recent.value = const [];
    }
  }

  /// Record a freshly solved scan as the newest entry (capped to [_maxEntries]).
  static Future<void> record(PracticeProblem problem) async {
    final entry = ScanHistoryEntry(
      question: problem.question,
      answer: problem.answer,
      steps: problem.steps,
      solvedAt: DateTime.now(),
    );
    recent.value = [entry, ...recent.value].take(_maxEntries).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(recent.value.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> clear() async {
    recent.value = const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
